**Who to sue:** lumyni

[Changelog](https://github.com/felixLumyni/battlepatch/blob/main/battlepatch/changelog.txt)

[Characters currently patched](https://github.com/users/felixLumyni/projects/2)
# How to build
Did you know that .pk3's are just .zip's? Yes, really. Just zip the contents of the inner "battlepatch" folder (not the folder itself!) and rename the result from .zip to .pk3 and it should be ready to load in-game. If you don't have anything to zip with, try [7Zip](https://www.7-zip.org/).

In case this is something you want to do often, below are some extra tools you can use to automate the process of zipping and launching the game.

### Python compiler and tester (Optional):

Use the [SRB2ModCompiler](https://github.com/felixLumyni/SRB2ModCompiler2) python script!

Example args: ``-skipintro -server +wait 1 -warp tutorial +downloading off +addfile ZBa_Battlemod-v9.3.pk3 caceepass.pk3 +wait 3 +skin Cacee +color Kiwi``

### Example batch (.bat) file tester (Optional):

```
cd "[PATH TO SRB2]"
Start "" srb2win.exe -file "[PATH TO THIS REPO]\battlepass.pk3" -server +skin Cacee +color Kiwi +wait 1 +"map tutorial -f" +downloading off
```
