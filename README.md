**Who to sue:** lumyni

# CHARACTERS CURRENTLY PATCHED:
- Maimy
- HorizonChars (Milne & Iclyn)
- Whisper
- StephChars (Skip & Jana)
- Willo

# DEPRECATED, AND THUS REMOVED:
- Tangle
- Maimy
- Whisper
- TeamKinetic
- Shadow
- Robe
- Cacee

# How to build
Did you know that .pk3's are just .zip's? Yes, really. Just zip the contents of the inner "battlepatch" folder (not the folder itself!) and rename the result from .zip to .pk3 and it should be ready to load in-game. If you don't have anything to zip with, try [7Zip](https://www.7-zip.org/).
Optional: Create a batch (.bat) file that can be used to easily test in-game
```
cd "[PATH TO SRB2]"
Start "" srb2win.exe -file "[PATH TO THIS REPO]\battlepatch.pk3" -server +wait 1 +"map tutorial -f" +downloading off
```
If you are a modder, you can also use the [SRB2Compiler](https://github.com/felixLumyni/SRB2-compiler) python script, it's heavily work-in-progress but is already enough to save you the trouble of having to manually zip and launch the game every time. Feel free to ask Lumyni about its usage since its current UI may be a bit confusing.