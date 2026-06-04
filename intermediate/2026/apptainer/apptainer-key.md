# Apptainer PGP Key Management: Create & Publish to keys.openpgp.org

**Audience:** HPC System Administrators  
**Applies to:** Apptainer 1.x (all current releases)  
**Keyserver:** [keys.openpgp.org](https://keys.openpgp.org)

---

## Overview

Apptainer uses PGP keys to **sign** and **verify** SIF container images. When a
user signs a container, a cryptographic signature is embedded directly into the
SIF file. Anyone with access to the corresponding public key can then verify
that the container hasn't been modified since it was signed.

Publishing your public key to `keys.openpgp.org` — Apptainer's default
keyserver — enables seamless remote verification without requiring users to
manually distribute or import public keys out-of-band.

### Why this matters for HPC sites

- Users can verify container provenance before execution
- Apptainer's optional Execution Control List (ECL) can restrict execution to
  containers signed by trusted keys (see the [admin guide](https://apptainer.org/docs/admin/latest/))
- Pipeline automation can enforce signature checks at job submission time
- Signatures survive container transfers between sites — they're embedded in
  the SIF file, not stored externally

---

## Prerequisites

- Apptainer installed (any 1.x release)
- An email address accessible to you — the keyserver sends a verification
  email to the address embedded in the key
- Outbound HTTPS access to `keys.openpgp.org` from the host where you're
  running these commands (a login node is typical)

> **Note for air-gapped clusters:** If your login nodes cannot reach
> `keys.openpgp.org`, perform the push from an internet-connected workstation
> after exporting the key. See [Exporting and Importing Keys](#exporting-and-importing-keys) below.

---

## Step 1 — Generate a Key Pair

Use the `key newpair` subcommand to create a new PGP key pair stored in
Apptainer's local keyring:

```bash
apptainer key newpair
```

You will be prompted for:

| Field | Notes |
|---|---|
| **Name** | Your name or a role name (e.g., `HPC Team`) |
| **Email** | Must be a real, accessible address — the keyserver sends a verification email here |
| **Comment** | Optional; useful for identifying key purpose (e.g., `cluster signing key`) |
| **Passphrase** | Protects your private key; required each time you sign a container |

Example session:

```
Enter your name (e.g., John Doe)          : HPC Admin
Enter your email address (e.g., john.doe@example.com) : hpcadmin@university.edu
Enter optional comment (e.g., development keys) : cluster signing key 2025
Enter a passphrase :
Retype your passphrase :
Generating Entity and OpenPGP Key Pair... done
```

> **Passphrase guidance:** Use a strong passphrase and store it in a password
> manager or secrets vault. You cannot recover a lost passphrase.

---

## Step 2 — List Local Keys and Get Your Fingerprint

Verify the key was created and retrieve its fingerprint:

```bash
apptainer key list
```

Example output:

```
Public key listing (/home/user/.apptainer/keys/pgp-public):

0)  User:              HPC Admin (cluster signing key 2025) <hpcadmin@university.edu>
    Creation time:     2025-06-04 10:00:00 -0700 MST
    Fingerprint:       E5F780B2C22F59DF748524B435C3844412EE233B
    Length (in bits):  4096
```

Copy the full 40-character **fingerprint** — you'll use it in the push step.

---

## Step 3 — Confirm the Target Keyserver

Check which keyserver Apptainer is configured to use:

```bash
apptainer remote list
```

Look for the `Keyservers` section:

```
Keyservers
==========

URI                       GLOBAL  INSECURE  ORDER
https://keys.openpgp.org  YES     NO        1*

* Active cloud services keyserver
```

`keys.openpgp.org` is the Apptainer default. No additional configuration is
needed unless your site uses a custom or private keyserver (see
[Keyserver Management](#keyserver-management) below).

---

## Step 4 — Push Your Public Key

Push the public key to the keyserver using the fingerprint from Step 2:

```bash
apptainer key push <FINGERPRINT>
```

Example:

```bash
apptainer key push E5F780B2C22F59DF748524B435C3844412EE233B
```

Expected output:

```
WARNING: No default remote in use, falling back to default keyserver: https://keys.openpgp.org
INFO:    Key server response: Upload successful. This is a new key, a welcome email has been sent.
public key 'E5F780B2C22F59DF748524B435C3844412EE233B' pushed to server successfully
```

To push to a specific keyserver URL explicitly:

```bash
apptainer key push --url https://keys.openpgp.org <FINGERPRINT>
```

---

## Step 5 — Verify Your Email Address ⚠️

**This step is required.** The key is uploaded but not yet publicly
discoverable.

Check the inbox of the email address you used in Step 1. You'll receive a
message from `noreply@keys.openpgp.org`. Click the verification link inside.

Until email verification is complete:

- The key **cannot be searched by email address** on the keyserver
- Remote `apptainer verify` operations against containers you've signed will
  **fail** for other users — they won't be able to auto-fetch your public key

Once verified, your key will be live and searchable at:

```
https://keys.openpgp.org/search?q=your@email.address
```

---

## Step 6 — Sign a Container

With a published key, sign SIF container images using:

```bash
apptainer sign my_container.sif
```

You'll be prompted for your key passphrase. The signature is embedded directly
into the SIF file — no separate signature file is needed.

If you have multiple keys in your local keyring, specify one by fingerprint:

```bash
apptainer sign --fingerprint E5F780B2C22F59DF748524B435C3844412EE233B my_container.sif
```

---

## Step 7 — Verify a Signed Container

```bash
apptainer verify my_container.sif
```

If your public key is in the local keyring:

```
[LOCAL]   Signing entity: HPC Admin (cluster signing key 2025) <hpcadmin@university.edu>
[LOCAL]   Fingerprint: E5F780B2C22F59DF748524B435C3844412EE233B
Objects verified:
ID  |GROUP   |LINK    |TYPE
------------------------------------------------
1   |1       |NONE    |Def.FILE
2   |1       |NONE    |JSON.Generic
3   |1       |NONE    |JSON.Generic
4   |1       |NONE    |FS
Container verified: my_container.sif
```

If the public key is not local but has been pushed to the keyserver, Apptainer
fetches it automatically:

```
[REMOTE]  Signing entity: HPC Admin (cluster signing key 2025) <hpcadmin@university.edu>
[REMOTE]  Fingerprint: E5F780B2C22F59DF748524B435C3844412EE233B
...
Container verified: my_container.sif
```

The `[REMOTE]` label confirms the key was retrieved live from the keyserver.

---

## Exporting and Importing Keys

### Export (for backup or transfer to another host)

Export the public key:

```bash
apptainer key export --armor mypubkey.asc <FINGERPRINT>
```

Export the private key (treat this file like a credential — keep it encrypted
and off shared storage):

```bash
apptainer key export --armor --secret myprivkey.asc <FINGERPRINT>
```

### Import

```bash
apptainer key import myprivkey.asc
```

You'll be prompted to set or confirm a passphrase on import.

### Pulling a Public Key from the Keyserver

If you've removed your local copy of a public key, retrieve it by fingerprint:

```bash
apptainer key pull <FINGERPRINT>
```

Or search first by email:

```bash
apptainer key search user@example.com
```

> **Important:** Pulling from the keyserver only restores the **public** key.
> The private key cannot be recovered from the keyserver — back it up before
> you need it.

---

## Key Management Tips

### Back up your private key

```bash
apptainer key export --armor --secret ~/apptainer-privkey-backup.asc <FINGERPRINT>
```

Store this backup in a secure location (secrets manager, encrypted offline
storage, institutional vault). If you lose the private key, you cannot sign
new containers or resign existing ones with that identity.

### Generate a revocation certificate

If your private key is ever compromised, you'll want to be able to revoke the
corresponding public key on the keyserver. Apptainer does not currently
generate standalone revocation certificates directly, but you can revoke via
`gpg` if you export the key pair to GPG first:

```bash
# Import your Apptainer key into GPG
gpg --import myprivkey.asc

# Generate revocation certificate
gpg --output revoke.asc --gen-revoke <FINGERPRINT>
```

Store the revocation certificate alongside your private key backup.

### Key expiration

Apptainer key pairs do not expire by default. For sites with formal key
lifecycle policies, use `gpg` to set an expiration date before or after
creation and then re-upload via `apptainer key push`.

---

## Keyserver Management

### View configured keyservers (admin)

```bash
apptainer keyserver list
```

### Add a secondary or private keyserver

Site admins can layer in a self-hosted keyserver (e.g., [Hagrid](https://gitlab.com/hagrid-keyserver/hagrid)):

```bash
sudo apptainer keyserver add https://keyserver.youruniversity.edu
```

Control lookup order with `--order`:

```bash
sudo apptainer keyserver add --order 1 https://keyserver.youruniversity.edu
```

With this configuration, Apptainer checks your internal keyserver first, then
falls back to `keys.openpgp.org`. This is useful for air-gapped or
security-sensitive environments where you want full control over trusted key
distribution.

### Remove a keyserver

```bash
sudo apptainer keyserver remove https://keyserver.youruniversity.edu
```

---

## Quick Reference

| Task | Command |
|---|---|
| Generate key pair | `apptainer key newpair` |
| List local keys | `apptainer key list` |
| Push public key | `apptainer key push <FINGERPRINT>` |
| Pull public key | `apptainer key pull <FINGERPRINT>` |
| Search keyserver | `apptainer key search <email or fingerprint>` |
| Export public key | `apptainer key export --armor pub.asc <FINGERPRINT>` |
| Export private key | `apptainer key export --armor --secret priv.asc <FINGERPRINT>` |
| Import key | `apptainer key import key.asc` |
| Sign a container | `apptainer sign my_container.sif` |
| Verify a container | `apptainer verify my_container.sif` |
| List keyservers | `apptainer keyserver list` |
| Add keyserver (admin) | `sudo apptainer keyserver add <URL>` |

---

## References

- [Apptainer Signing & Verification Docs](https://apptainer.org/docs/user/latest/signNverify.html)
- [Apptainer Keyserver Management Docs](https://apptainer.org/docs/user/latest/keyserver.html)
- [Apptainer Key Command Reference](https://apptainer.org/docs/user/latest/key_commands.html)
- [keys.openpgp.org](https://keys.openpgp.org)
- [Apptainer Admin Guide — Execution Control List (ECL)](https://apptainer.org/docs/admin/latest/)
