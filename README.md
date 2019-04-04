# pkmn-ess-egg-challenge
A modular script to easily implement egg parsing and egg generation to a Pokemon (RPG Maker, Pkmn Essentials) game.



### What is it?

<https://pokemondb.net/pokebase/286561/what-is-an-egglocke>

An "Egglocke" is a challenge variant for Pokemon games. This code makes it easier to implement by allowing you to to collect a wide number of eggs (or, more obviously, very easily randomly generate eggs), and share them with friends, and have them add them as eggs in their own game's PCs.

### How do I use it?



1. Navigate to the scripts section of RPG Maker XP and insert a new script above "Main".

2. Copy and paste the contents from "Egglocke.rb" into that script.

3. Create a folder named "Egglocke" in the main game directory (To be filled with egg data)

4. In the overworld, run the command 

5. ```
   Kernel.initiateEgglocke
   ```

   to begin the parsing/loading process.



### How does it work?

- An "egg" is stored in the following way:

  - ```
    Species,Nickname,Item,Ability #,Gender,Nature,IV 1, IV 2, IV 3, IV 4, IV 5, IV 6,Move1,Move2,Move3,Move4,-1,-1,
    ```

    For example:

  - ```
    95,"Toph",71,0,Male,Naughty,31,31,31,31,31,31,694,694,303,303,-1,-1,
    ```

  - Would be an Onix named Toph, equipped with whatever item has an id of 71, etc.

- We can add text files filled with eggs to our Egglocke folder

  - Any text file is simply a line-separated list of eggs.
  - Each egg in the list is added to a the player's PC when that Egglocke file is selected