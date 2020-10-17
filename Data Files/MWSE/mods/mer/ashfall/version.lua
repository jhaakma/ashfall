local versionFile = io.open("Data Files/MWSE/mods/mer/ashfall/version.txt", "r")
local version = ""
for line in versionFile:lines() do -- Loops over all the lines in an open text file
    version = line
end
return version