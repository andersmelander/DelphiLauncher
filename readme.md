# Delphi Launcher

## Using Delphi with different versions of 3rd party packages

### Usage

Note: Terms are explained in the section "How to create a new environment..." below.

Execute the `start.ps1` PoweShell script from the environment root folder of the desired run-time environment.

The script will verify that the environment is up to date by comparing the environment version in the registry with the one in the `enviroment.ini` file on disk. If it's not up to date, the script deletes the current package files, extracts the new ones from the zip file, and updates the registry.

It then copies the current Delphi registry keys to a custom registry branch and updates it with the environment package files.

Finally, it launches Delphi with a command line that directs it to use the custom registry branch.

### How to create a new environment based on a current Delphi installation

Note: 

> **Quoted, bold** texts are examples.

1) Create a folder to hold the environment.
   
   > **DelphiLauncher\MyProject**
   
   We call this the *environment root folder*.

2) Create a folder named `Packages` under the environment root folder.
   
   > **DelphiLauncher\MyProject\Packages**
   
   We call this the *package folder*.

3) Export the content of the `HKEY_CURRENT_USER\Software\Embarcadero\BDS\<version>\Known Packages` registry key to a reg file named `packages.reg` in the environment root folder.
   <version> denotes the version of Delphi. For example 20.0 for Delphi 10.3

4) Rename `packages.reg` to `packages.txt`
   
   > **DelphiLauncher\MyProject\packages.txt**

5) Edit `packages.txt`
   Remove the first 3 lines of the file so the file only contains the package list.

6) For all the design-time packages in the list and all the run-time packages they depend on, copy the files to sub-folders [^1] of the package folder.
   
   > **DelphiLauncher\MyProject\Packages\Graphics32\GR32_DD110.bpl**
   > 
   > **DelphiLauncher\MyProject\Packages\Graphics32\GR32_RD110.bpl**
   > 
   > **DelphiLauncher\MyProject\Packages\DevExpress\dcldxRibbonRS28.bpl**
   > *etc*

7) Zip the content of the package folder into a file named `packages.zip` in the environment root folder.
   
   > **DelphiLauncher\MyProject\packages.zip**
   
   The package folder can now be deleted. The folder and its content will be recreated by the script on demand.

8) Add the `packages.txt` file to `packages.zip`.
   The `packages.txt` file can now be deleted. The file will be recreated by the script on demand.

9) Create a text file named `environment.ini` in the environment root folder.
   
   > **DelphiLauncher\MyProject\environment.ini**
   
   The file is an ini-file with the following content:
   
       [environment]
       delphi=<version>
       project=<name>
       revision=<value>
   
   where
   
   * <version> is the version of Delphi used.
     It must match the value of <version> mentioned in step 3.
     
     > **delphi=20.0**
   
   * <name> is the name of the environment.
     
     > **project=My project**
     
     The value is displayed in the Delphi title bar.
   
   * <value> is the environment revision number/id.
     
     > **revision=1**
   
   The combination of <name><value> is used to detect if the environment has been updated and should be refreshed.
   If you change, add, or remove any package files, one or both of <name> and <value> must be changed. Typically only <value> is changed.

10) Copy the `start.ps1` script from another environment into the environment root folder.
    
    > **DelphiLauncher\MyProject\start.ps1**

Note:

- Packages that are listed in `packages.txt` but do not exist on disk are ignored.

- Packages located in `$(BDSBIN)` are assumed to be Delphi's own and are left as-is.

- The paths in `packages.txt` are ignored. Only the file names are significant.

- It's a good idea to place a text file named `versions.txt` in the environment root folder that  contains the name and version numbers of the libraries contained in the package sub-folders. This makes it easier to determine what an environment contains.
  
  > **DevExpress 2022.1.3.0**
  > **TeeChart 9.0.26.0**
  > **madExcept 5.1.2 (madCollection 2.8.11.7)**

- If the project will be used with several different versions of Delphi, just create an environment root folder for each version.
  
  > **DelphiLauncher\MyProject\Delphi 10.3**
  > **DelphiLauncher\MyProject\Delphi 11.0**

[^1]: The names of the sub-folders are not important. The sub-folders are only used to better organize the files.

### Revision control

The following files define an environment and can be placed under revision control (e.g. checked into a Git repository):

- `start.ps1`

- `environment.ini`

- `packages.zip`

- `versions.txt` (optional)

All other files are transitory and can be ignored.

For Git it might be a good idea to enable [LFS](https://www.atlassian.com/git/tutorials/git-lfs) for zip files on the repository if the file is large. YMMV.