# RE2 bug with yarn
see: https://github.com/uhop/node-re2/issues/92

## Repro steps

1.  ```yarn install```
2.  ```node .```
  - ensure that the app runs okay, showing output for argon2 and re2.
3.  ```yarn remove argon2```
4.  ```yarn add argon2```
5.  ```node .```
  - The app will fail with ```Error: Cannot find module './build/Release/re2'```
6.  ```yarn install```
7.  ```node .```
  - The app will still fail with ```Error: Cannot find module './build/Release/re2'```