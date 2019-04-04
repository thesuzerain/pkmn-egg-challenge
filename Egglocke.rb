###############################################
#
# "Egg Challenge" / "Egglocke" script
# for RPG Maker / Pkmn Essentials
#
# by thesuzerain
#
# Insert this script above "main"
#
#
# This allows for functionality to read, parse, and add eggs in the folders to the ingame PC
# It does not implement restrictions on accessing those eggs 
# (ie many challenges will prohibit taking an egg unless you catch a Pokemon).
#
################################################


# Defines banned species and legal items
# - banned species include Pokemon for which no member of its evolutionary line is allowed
#   - generally this is used for legendaries (which can't have eggs)
# - legal items are items that can be generated for any egg

BANNED_SPECIES = [PBSpecies::MEW,PBSpecies::ZAPDOS,PBSpecies::MOLTRES,
          PBSpecies::ARTICUNO,PBSpecies::MEWTWO]

LEGAL_ITEMS = [PBSpecies::POTION,PBSpecies::SUPERPOTION,PBSpecies::FIRESTONE,
          PBSpecies::WATERSTONE,PBSpecies::THUNDERSTONE]


def checkIsIDLegal(eggid)
  return !BANNED_SPECIES.include?(eggid)
end

def checkIsItemLegal(itemid)
  return true if LEGAL_ITEMS.include?(itemid)
end

def pbCheckEggFileValid(string)
  return File.exist?("Egglocke/"+string+".txt")     
end




# Confirms that a given Pokemon species is allowed to learn a given move
# Used for sanity checking to ensure no illegal eggs (with illegal moves) can be made

def isMoveLegalForSpecies(species,move,eggEmerald)
    legality=false
    
    # We open the attackRS.dat to scan data for allowed learnable moves
    atkdata=pbRgssOpen("Data/attacksRS.dat","rb")
    offset=atkdata.getOffset(species-1)
    length=atkdata.getLength(species-1)>>1
    atkdata.pos=offset
    for k in 0..length-1
      
        # For every given learnable move, we check to see if it matches
        # and if it does, if it can learn it at level 1
       level=atkdata.fgetw
       move2=atkdata.fgetw
       if move2 == move && level <= 1
          legality=true 
          break
        end
    end
    atkdata.close
    
    # If the legality flag is not yet marked, we check to see if it is an allowed egg move
    # by repeating a similar process for the list of egg moves
    if !legality
      eggEmerald.pos=(species-1)*8
      offset=eggEmerald.fgetdw
      length=eggEmerald.fgetdw
      if length>0
        eggEmerald.pos=offset
        first=true
        j=0; loop do break unless j<length
          atk=eggEmerald.fgetw
          legality=true if atk == move
           break if atk == move
          j+=1
        end
      end
    end
    return legality
  end


# We get a list of every "Egglocke" file (text files containing lists of egg) in the folder for display
def getEgglockeNames
    ary = []
    temp = Dir.entries("Egglocke/")# rescue nil)
    if temp != nil
    for string in temp
      if string.include?(".txt") && !string.include?("readme.txt")
        string = string[0..-5]
        ary.push(string)
      end
    end
  end
  if ary.length==0
      Kernel.pbMessage("No files were found")
      return false
  end
  return ary
end


# We parse an "Egglocke" file to get a list of all the eggs 
# Returns an array of PokeBattle_Pokemon (or nil for eggs that didn't properly parse)
# Pokemon can be immediately placed into the PC.
# 
# string: file contents to parse
# ignore: flag. If false, returns an error if a bad egg is found. If true, ignores the bad egg and skips to the next one.
#
def getEggsFromFile(string,ignore=false)
  
  
  records=[]
  constants=""
  itemnames=[]
  itemdescs=[]
  maxValue=0
  eggs=[]
  numberline = 0
  failedLastEgg=false

  # We open the Pokemon data file for legality checks
  eggEmerald=File.open("Data/eggEmerald.dat","rb")
  
  # We iterate through each line of the "Egglocke" file
  pbCompilerEachPreppedLine("Egglocke/"+string+".txt"){|line,lineno|
    # Do not edit: extracts expected data types (ie s = string, i = int)
    linerecord=pbGetCsvRecord(line,lineno,[0,"vsuunnuuuuuuiiii"])
    
    egg = nil
    
    # We should only increase the number we are on if the past egg failed 
    # (ie: overwrite bad eggs with good eggs)
    if !failedLastEgg
      numberline += 1
    else
      failedLastEgg=false
    end
    
    # First value of a stored egg should be its species
    if linerecord[0]!="" && linerecord[0] && linerecord[0].to_i != 0
      # ID is illegal => fails
      if !checkIsIDLegal(linerecord[0].to_i)
        return "Pokemon species "+PBSpecies.getName(linerecord[0].to_i).to_s+"("+linerecord[0].to_s+") is illegal. It is either a legendary or a non-basic Pokemon, and is not allowed to be used. (Line:"+numberline.to_s+")" if !ignore
        failedLastEgg=true
        break
      end
      egg = PokeBattle_Pokemon.new(linerecord[0].to_i,1,nil,false)
    else
      # Species is 0 or otherwise null => impossible, fails
      return "Error on line "+numberline.to_s+", the first part. Could not read, or not a number." if !ignore
      failedLastEgg=true
      break
    end
    
    # Second value is a species name
    if linerecord[1]!="" && linerecord[1]
      egg.name=linerecord[1]
    else
      # Name is empty or otherwise undefined
      return "Error on line "+numberline.to_s+", the nickname (second part). Could not be read." if !ignore
      failedLastEgg=true
      break
    end
    
    # Third value is item.
    if linerecord[2]!="" && linerecord[2]
      if checkIsItemLegal(linerecord[2].to_i)
        egg.item=linerecord[2].to_i
      else
        # Item is illegal
        return "Item equipped to Pokemon on line "+numberline+" "+PBItems.getName(linerecord[2].to_i)+" is illegal." if !ignore
        failedLastEgg=true
        break
      end
    else
      # Item is empty or null
      return "Error on line "+numberline.to_s+", the item (third part). Could not be read." if !ignore
      failedLastEgg=true
      break
    end
    
    # Fourth value is the ability. Should be 0, 1, 2.
    if linerecord[3]!=""  && linerecord[3] && linerecord[3].to_i < 3 && linerecord[3].to_i > -1
        egg.setAbility(linerecord[3].to_i)
      else
        # Ability is empty, null, or not 0,1,2.
      return "Error on line "+numberline.to_s+", the ability (fourth part). Could not be read." if !ignore
      failedLastEgg=true
      break
    end
    
    # Fifth value is gender marker
    if linerecord[4]!="" && linerecord[4]
      if linerecord[4]=="Male"
        linerecord[4]=0
      elsif linerecord[4]=="Female"
        linerecord[4]=1
      elsif linerecord[4]=="Genderless"
        linerecord[4]=2
      else
        linerecord[4]=linerecord[4].to_i
      end
       
      tempint = linerecord[4].to_i-1
      egg.setGender(linerecord[4].to_i)
    else
      # Bad gender
      return "Error on line "+numberline.to_s+", the gender (5th part). Could not be read." if !ignore
      failedLastEgg=true
      break
    end
    
    # Sixth value is nature marker
    if linerecord[5]!="" && linerecord[5] 
          egg.setNature(parseNature(linerecord[5]))
        else
          # Not a valid nature number
      return "Error on line "+numberline.to_s+", the nature (6th part). Could not be read." if !ignore
      failedLastEgg=true
      break
    end

    # Seventh through twelfth are "IVs". 
    for integer in 6..11
      if linerecord[integer]!="" && linerecord[integer]
        egg.iv[integer-6] = linerecord[integer]
      else
        # Invalid IVs. Don't need to check number sanity for less than 31.
        return "Error on line "+numberline.to_s+", in the IVs (6-11th part). Could not be read." if !ignore
        failedLastEgg=true
        break
      end
    end
    
    # Thirteen through sixteen are moves
    for integer in 12..15
      if linerecord[integer]!="" && linerecord[integer]               
        if isMoveLegalForSpecies(linerecord[0].to_i,linerecord[integer].to_i,eggEmerald)
          egg.moves[i]=PBMove.new(linerecord[0].to_i,linerecord[integer].to_i)
        else
          # We do not throw an error if the move is illegal here
          # We just have an empty move slot (which is OK).
        end
      else
        return "Error on line "+numberline.to_s+", in the moves (12-15th part). Could not be read." if !ignore
        failedLastEgg=true
        break
      end
    end
    
    eggs[numberline] = egg
  }
  eggEmerald.close
  return eggs
end



# Call this function from the overworld to initiate egglocke.
#
# ignore: flag. If false, returns an error if a bad egg is found. If true, ignores the bad egg and skips to the next one.
#
def initiateEgglocke(ignore = false)
  
  listOfEggs = []
  
  # Fetches all the file names for egglocke instances the player has ready
  array=Kernel.getEgglockeNames
  
  array.push("Cancel")
  fileno=Kernel.pbMessage("Load eggs from which file?",array)
  if fileno != array.length-1
    return false
  else
    temp=false
    while !temp do
      listOfEggs=Kernel.getEggsFromFile(n,ignore)
      
      # If we are not ignoring error messages and one is returned,
      # display it and abort.
      if !ignore && listOfEggs.is_a?(String)
        if Kernel.pbMessage(listOfEggs)
          return
        end
      end
    else
      Kernel.pbMessage("Eggs were succesfully loaded.")
      temp=true
    end
  end
  # We iterate through the list of eggs and put them into the PC, one box at a time
  # Each PC box has 30 available places (so 30 "t"s to a "y")
  for j in 1..listOfEggs.length-1
    if listOfEggs[j]!=nil
      egg = listOfEggs[j]
      t=j-1
      y=0
      while 1==1
        if t>=30
          y+=1
          t-=30
        else
          break
        end
      end
      egg.eggsteps=5
      egg.calcStats
      $PokemonStorage[y,t]=egg
    end
  end
end
  
  return true
end
