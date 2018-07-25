'****************************************************************************************************************
'*                  			EpicMusicPlayer Playlist Creator 4.0
'*                      		 	Copyright by yess
'*
'* if you want to modify or include this with your addon, please ask first.
'*
'* Set folder with the music eg: "C:\Program Files\World of Warcraft\MyMusic"
'* The folder MUST be within the World of Warcraft folder.
musicfolder = "..\..\..\MyMusic"
'* This is where the addon (not this script) will look for the music. It's relative to the WoW folder.
realtiveMusicFolder = "MyMusic\\"
'****************************************************************************************************************

'force the script to run in from a console
CheckStartMode

'check Windows Version
dim indexTitle, indexArtist, indexAlbum, indexTime
if getWindowsVersion() > "5.1" then
	'Windows Vista, 7, 8 and 8.1
	indexTitle = 21
	indexArtist = 20
	indexAlbum = 14
	indexTime = 27
elseif getWindowsVersion() = "5.1" then
	'Windows XP
	indexTitle = 10
	indexArtist = 16
	indexAlbum = 17
	indexTime = 21
else
	WScript.Echo "This playlist generator does not work with your windows version."
	Wscript.Quit
end if

if WScript.Arguments.Count > 0 then
		if WScript.Arguments(0) = "gamemusic" then
			WScript.Echo "Adding Game Music Mode is ON!"
			addingGameMusic = 1
		end if
end if


dim totalNumberOfSongs, listCount
totalNumberOfSongs = 0
set objShell = CreateObject("Shell.Application")
set objFSO = createobject("Scripting.FileSystemObject")

if not objFSO.FolderExists(musicfolder) then
	if musicfolder = "..\..\..\..\mymusic" then
		WScript.Echo "Music Folder not found: " & objFSO.GetFolder("..\..\..\..\").Path & "\MyMusic"
	else
		WScript.Echo "Music Folder not found: " & musicfolder
	end if
	Wscript.Quit
end if
musicfolder = objFSO.GetFolder(musicfolder).Path

const adTypeText = 2
const adSaveCreateOverWrite = 2
dim BinaryStream
set BinaryStream = CreateObject("ADODB.Stream")
BinaryStream.Type = adTypeText
BinaryStream.CharSet = "utf-8"
BinaryStream.Open

'WScript.Echo "Generating the playlist, this may take some time..."
BinaryStream.WriteText "--Created by PlaylistCreator version 4.0" & Vbcrlf
BinaryStream.WriteText "local EpicMusicPlayer = LibStub(""AceAddon-3.0""):GetAddon(""EpicMusicPlayer"")" & Vbcrlf
BinaryStream.WriteText "if not EpicMusicPlayer then return end" & Vbcrlf

set objFolder = objFSO.GetFolder(musicfolder)
set folder = objShell.NameSpace(musicfolder)
playlistIndex = 0
'create a playlist for all the files in the music folder
writePlaylistHeader(objFSO.GetFolder(musicfolder).Name)
WScript.Echo "Generating playlist: " & objFSO.GetFolder(musicfolder).Name
listCount = 0
for each file in folder.items
	x = getSongInfo(file,folder)
next
BinaryStream.WriteText "}" & Vbcrlf
BinaryStream.WriteText "EpicMusicPlayer:AddPlayList(""playlist"", playlist" & playlistIndex & ", false)" & Vbcrlf
playlistIndex = playlistIndex + 1

'create a playlist for each subfolder of the music folder
for each objFolder in objFolder.SubFolders
	if objFolder.Files.Count > 0 or objFolder.Subfolders.count > 0 then
		wscript.echo objFolder
		if objFolder.name = "sound" then
			addingGameMusic = 1
			writeGameMusicInfo = 1
		else
			addingGameMusic = 0
		end if
		CreatePlaylist objFolder.Path
		playlistIndex = playlistIndex + 1
	end if
next

BinaryStream.SaveToFile "CustomMusic.lua", adSaveCreateOverWrite

WScript.Echo "Done! " & Vbcrlf & totalNumberOfSongs & " music files written to Playlist."
if writeGameMusicInfo = 1 then
	WScript.Echo Vbcrlf & "Files in the folder named ""sound"" were added as game music and will not play if they are not present in the game data."
end if

'enum all files from given directory
sub GetFiles(byval strDirectory)
	set objFolder = objFSO.GetFolder(strDirectory)
	set folder = objShell.NameSpace(strDirectory)
	for each file in folder.items
		'wscript.echo file
		x = getSongInfo(file,folder)
	next
	for each objFolder in objFolder.SubFolders
		GetFiles objFolder.Path
	next
end sub

sub CreatePlaylist(byval strDirectory)
	'strPlayListName = strDirectory
	'write playlist head
	writePlaylistHeader(objFSO.GetFolder(strDirectory).Name)
	'write music files
	WScript.Echo "Generating playlist for files in: " & objFSO.GetFolder(strDirectory).Name
	listCount = 0
	GetFiles strDirectory
	'write end of playlist
	BinaryStream.WriteText "}" & Vbcrlf
	BinaryStream.WriteText "EpicMusicPlayer:AddPlayList(""" & objFSO.GetFolder(strDirectory).Name & """, playlist" & playlistIndex & ", false)" & Vbcrlf
end sub

function getSongInfo(file,folder)
	dim album, title, time, artist, ext, path
	ext = Ucase(Right(file.Path, 3))
	if ext = "MP3" then
		title = Replace(folder.GetDetailsOf(file, indexTitle) , """", "")
		artist = Replace(folder.GetDetailsOf(file, indexArtist) , """", "")
		album = Replace(folder.GetDetailsOf(file, indexAlbum) , """", "")
		time = getTime(file,folder)
		'remove musicdir from path
		path = Right(file.Path,len(file.Path)-len(musicfolder)-1)
		path = Replace(path, "\", "\\")
		'wscript.echo title & " - " & file
		if title = "" and len(file) > 4 then title = Left(file,len(file)-4) end if
		if time > 0 then
			listCount = listCount + 1
			totalNumberOfSongs = totalNumberOfSongs + 1
			x = writeSong(outfile, path, album, time,title, artist)
			WScript.Echo totalNumberOfSongs & " Writing: " & path
		end if
	end if
end function

function getTime(file,objFolder)
	dim time
	'get time from file hh:mm:ss
	time=objFolder.GetDetailsOf(file, indexTime)
	time=Split(time,":")

	if (UBound(time) - LBound(time) + 1)  > 2 then
		' convert hours, minutes and seconds strings to numbers and sumerize them
		getTime = (CInt(time(0))*60+CInt(time(1)))*60+CInt(time(2))
	else
		getTime = 0
	end if
end function

sub writePlaylistHeader(listName)
	BinaryStream.WriteText "local playlist" & playlistIndex &  " = {" & Vbcrlf & "	{" & Vbcrlf
	BinaryStream.WriteText "		[""ListName""] = """ & listName &"""," & Vbcrlf
	BinaryStream.WriteText "		[""PlaylistVersion""] = ""3.1""," & Vbcrlf
	BinaryStream.WriteText "		[""PlaylistType""] = ""generated""," & Vbcrlf
	BinaryStream.WriteText "		[""MusicDir""] = """ & realtiveMusicFolder & """," & Vbcrlf
end sub

function writeSong(outfile,path,album,time,title,artist)
	if listCount > 1 then
		BinaryStream.WriteText "	{" & Vbcrlf
	else
		BinaryStream.WriteText "        --first song" & Vbcrlf
	end if
	BinaryStream.WriteText "		[""Album""] = """ & album & ""","& Vbcrlf
	BinaryStream.WriteText "		[""Song""] = """ & title & ""","& Vbcrlf
	BinaryStream.WriteText "		[""Name""] = """ & path & ""","& Vbcrlf
	BinaryStream.WriteText "		[""Length""] = " & time &","& Vbcrlf
	BinaryStream.WriteText "		[""Artist""] = """ & artist & ""","& Vbcrlf
	if addingGameMusic = 1 then
			BinaryStream.WriteText "		[""WoW""] =  """ & "true" & ""","& Vbcrlf
	end if
	BinaryStream.WriteText "	},"& Vbcrlf
end function

function getWindowsVersion()
	'Option Explicit
	dim objWMI, objItem, colItems
	dim strComputer, VerOS, VerBig, Ver9x, Version9x, OS, OSystem

	on error resume next
	strComputer = "."
	set objWMI = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	set colItems = objWMI.ExecQuery("Select * from Win32_OperatingSystem",,48)

	for each objItem in colItems
		VerBig = Left(objItem.Version,3)
	next

	getWindowsVersion = VerBig
	set objWMI = nothing
	set colItems = nothing
end function


sub CheckStartMode
	' Returns the running executable as upper case from the last \ symbol
	strStartExe = UCase( mid( wscript.fullname, instrRev(wscript.fullname, "\") + 1 ) )

	if not strStartExe = "CSCRIPT.EXE" then
	' This wasn't launched with cscript.exe, so relaunch using cscript.exe explicitly!
	' wscript.scriptfullname is the full path to the actual script

	set oSh = CreateObject("wscript.shell")
		if WScript.Arguments.Count > 0 then
			oSh.Run "cmd /k cscript.exe """ & wscript.scriptfullname & """" & " " & WScript.Arguments(0)
		else
			oSh.Run "cmd /k cscript.exe """ & wscript.scriptfullname & """"
		end if
		wscript.quit
	end if
end sub

set BinaryStream = nothing
set objFolder = nothing
set folder = nothing
set objShell = nothing
set objFSO = nothing