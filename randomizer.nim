import json
import tables
import random

from os import absolutePath, getAppDir, joinPath

# TODO: generate N dwarfs/team (with option to ignore/avoid duplication)

# Call randomize() once to initialize the default random number generator
randomize()

let
  dwarfsJson = parseFile(joinPath(getAppDir(),"dwarfs.json"))
  perksJson = parseFile(joinPath(getAppDir(), "perks.json"))

proc randomizePerks(data: JsonNode): seq[JsonNode] =
  let
    passivePerks = data["passive"].getElems()
    activePerks = data["active"].getElems()
    passiveAmount = 3
    activeAmount = 2

  while result.len < passiveAmount:
    let el = sample(passivePerks)
    if el notin result:
      result.add(el)

  while result.len < passiveAmount + activeAmount:
    let el = sample(activePerks)
    if el notin result:
      result.add(el)


# proc getDwarf(dwarfs: JsonNode, name: string = ""): JsonNode =
#   if name != "":
#     for el in dwarfs:
#       if el["dwarf"].getStr == name:
#         result = el
#   else:
#     result = dwarfs[rand(0..3)]

# Common part to randomize tool
proc getRandomFieldValue(field: JsonNode): JsonNode  =
  case field.kind
  of JArray:
    result = sample(field.getElems)
  of JString:
     result = field
  else:
    discard

# Randomize tool/weapon and return result as JsonNode
proc randomizeTool(tool: JsonNode): JsonNode =
  case tool.kind
  of JArray:
    if tool[0].kind == JObject:
      # Get random tool from array
      result = tool[rand(0..tool.len-1)]
      # Randomize it mods
      for k,v in result["mods"].getFields:
        result["mods"][k] = getRandomFieldValue(v)
      # If contains overclock, pick up random overclock
      if result.hasKey("overclock"):
        result["overclock"] = sample(result["overclock"].getElems)

    else:
       result = sample(tool.getElems)

  of JObject:
    result = tool
    for k,v in result["mods"].getFields:
      result["mods"][k] = getRandomFieldValue(v)
      # If contains overclock, pick up random overclock
    if result.hasKey("overclock"):
      result["overclock"] = sample(result["overclock"].getElems)

  else: discard

# Main functio to fully randomize dwarf loadout
proc randomLodout(dwarf: JsonNode): JsonNode =
  result = dwarf
  for k,v in result.getFields():
    if k == "id" or k == "dwarf":
      continue
    else:
      result[k] = randomizeTool(v)

proc randomizeDwarfAndLayout: JsonNode =
  result = randomLodout(dwarfsJson[rand(0..dwarfsJson.len-1)])

proc printTool(tool: JsonNode) =
  if tool.hasKey("overclock"):
    echo "  Mods:"
    for _,v in tool["mods"].getFields():
      echo "   - ", v.getStr()

    echo "  Overclock: ", tool["overclock"].getStr()
  else:
    for _,v in tool["mods"].getFields():
      echo " - ", v.getStr()

  echo "\n"


proc printDwarf(dwarf: JsonNode) =
  echo "# Class - ", dwarf["dwarf"].getStr(), " #\n"

  echo "# Primary weapon - ", dwarf["primary"]["name"].getStr(), " #"
  printTool(dwarf["primary"])

  echo "# Secondary weapon - ", dwarf["secondary"]["name"].getStr(), " #"
  printTool(dwarf["secondary"])

  echo "# Pickaxe mod - ", dwarf["pickaxe"].getStr(), " #\n"

  echo "# Utility item - ", dwarf["utility"]["name"].getStr(), " #"
  printTool(dwarf["utility"])

  echo "# Traversal item - ", dwarf["traversal"]["name"].getStr(), " #"
  printTool(dwarf["traversal"])

  echo "# Throwable - ", dwarf["throwable"].getStr(), " #\n"

  echo "# ", dwarf["armor"]["name"].getStr(), " Armor Rig #"
  printTool(dwarf["armor"])

  echo "# Perks #"
  for perk in randomizePerks(perksJson):
    echo " - ", perk.getStr()

when isMainModule:
  var ranDworf = randomizeDwarfAndLayout()
  printDwarf(ranDworf)
