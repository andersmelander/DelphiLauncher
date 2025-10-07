This is an example of a complete DelphiLauncher setup for the imaginary FooBar project, using Delphi 12.

To try it out just execute `start.cmd`.

If you don't have Delphi 12 installed, which is what the example is set up for, then you need to first edit `enviroment.ini` to specify the desired [version of Delphi](https://docwiki.embarcadero.com/RADStudio/en/Compiler_Versions).

The `packages.zip` archive doesn't contain any actual package files as it would in a real setup (instead it just contains some empty placeholder files) so you will get a bunch of errors (*Bad Image, Can't load package*) when Delphi is starts. That is expected for this example and can be ignored.

The `start.cmd` in this folder just makes a copy of the `start.ps1` in the parent folder and execute that - because PowerShell sucks and one can't just call or include another script without the context changing to the folder of that script.