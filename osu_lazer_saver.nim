# Exports all songs (mp3) from osu!lazer
# to the songs folder from current directory.
# The SQL query might be not the best one,
# but it works for me, and I don't really know SQL :P
#
# Also that SQL query might break if osu!lazer DB schema changes, YMMV
import db_sqlite, strutils, os, strformat

const SongQuery = sql"""
select
  BeatmapMetadata.Artist,
  BeatmapMetadata.Author,
  BeatmapMetadata.Title,
  BeatmapSetInfo.OnlineBeatmapSetID,
  FileInfo.Hash
from
  BeatmapMetadata
    join BeatmapSetInfo
      on BeatmapMetadata.ID=BeatmapSetInfo.MetadataID
		join BeatmapSetFileInfo
			on BeatmapSetFileInfo.BeatmapSetInfoID=BeatmapSetInfo.ID
      AND BeatmapSetFileInfo.Filename=BeatmapMetadata.AudioFile
		join FileInfo
			on FileInfo.ID=BeatmapSetFileInfo.FileInfoID
"""

const targetDir = "songs"
createDir(targetDir)

let db = open(getHomeDir() / ".local/share/osu" / "client.db", "", "", "")
for row in db.getAllRows(SongQuery):
  let (artist, author, title, onlineSetId, hash) = (row[0], row[1], row[2], row[3], row[4])
  
  let audioFile = getHomeDir() / ".local/share/osu" / fmt"files/{hash[0]}/{hash[0..1]}/{hash}"
  let destFile = fmt"{artist} - {title} [{onlineSetId}].mp3".replace("/","")
  
  echo fmt"Copying {artist} - {title}..."
  copyFile(audioFile, targetDir / destFile)
  

db.close()