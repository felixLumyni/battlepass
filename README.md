# BATTLEPASS
(Previously known as BATTLEPATCH)

[Complete Changelog](https://github.com/felixLumyni/battlepass/blob/main/battlepass/changelog.txt)

[List of characters currently patched](https://github.com/users/felixLumyni/projects/2)
# How to build
Did you know that .pk3's are just .zip's? Yes, really. Just zip the contents of the "battlepass" folder (not the folder itself!) and rename the result from .zip to .pk3 and it should be ready to load in-game. If you don't have anything to zip with, try [7Zip](https://www.7-zip.org/) or [SRB2ModCompiler](https://github.com/felixLumyni/SRB2ModCompiler2).

Example args for SRB2ModCompiler: ``-skipintro -server +wait 1 -warp tutorial +downloading off +addfile ZBa_Battlemod-v9.3.pk3 caceepass.pk3 +wait 3 +skin Tails +color Rosy``

<details>
<summary>Example batch (.bat) file tester (deprecated):</summary>
  
```
cd "[PATH TO SRB2]"
Start "" srb2win.exe -file "[PATH TO THIS REPO]\battlepass.pk3" -server +skin Cacee +color Kiwi +wait 1 +"map tutorial -f" +downloading off
```
</details>
