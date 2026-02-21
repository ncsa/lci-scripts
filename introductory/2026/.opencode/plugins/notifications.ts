/**
 * Notifications Plugin
 * Sends macOS notifications when sessions complete
 */

export const NotificationPlugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        try {
          await $`osascript -e 'display notification "Session completed!" with title "OpenCode"'`
        } catch {
          // Ignore notification errors
        }
      }
    },
  }
}
