
# ukraine-vodafone-balance

*vodafone-balance.sh* is a bash script for automatic retreiving mobile account balance(s) for several *i-helper* accounts

### Output
Script generate output like this

```sh
$ vodafone-balance.sh

         nick1  095 xxx-yy-01   17,37 uah   Smartfon 3G Pervyj
         nick2  050 xxx-yy-02   27,89 uah   GSM tarif-I
         daddy  050 xxx-yy-03   32,69 uah   Some tarif-II
         mommy  099 xxx-yy-04   29,62 uah   Smartfon Zero
```

#### Input data
You have rename 'credentials.example' file to 'credentials' and fill it by
correct/appropriative data

```sh
declare -a CREDENTIALS=(
  "nickname1:99 123-45-67:pass1"
  "nickname2:50 123-45-67:pass2"
      "daddy:66 123-45-67:pass3"
      "mommy:95 123-45-67:pass4"
)

# DATA_DIR=/var/cache/some...
```

Phone and and password is the login pair to *mts-ihelper* page on  mobile operator's site

If you will not  specify **DATA_DIR** directory, cache files be stored to appropriative directory in the script directory

### Options
Only one option 
```sh
  --dry-run
```
re-prints data obtained for previous script invocation

Enjoy!
