# Ollama on Sol at ASU

## Steps 

create ollama dir in your application/software ie '/packages/apps/ollama/'

copy the script download_ollama.sh to that directory.

copy the dir scripts/ to the same directory.

copy the dir ollama in the modules dir to your modules path. ie '/packages/modulefiles/apps/'

to download a new version run the script with the latest version as an input parameter.

```bash
./download_ollama.sh 0.30.3
```

In the modules dir, copy one module to the new version number then edit the file to change the version number in the module lua file.

```bash 
cp 0.20.4.lua 0.30.3.lua
vim 0.30.3.lua
:%s/0.20.4/0.30.3/g # ths will replace all instances of 0.20.4 with 0.30.3 in the file.
```


## NOTE 
  - You will need to edit lines 91 - 92, edit the path to the scripts the alias uses. 
