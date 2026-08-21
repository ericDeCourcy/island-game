Plan.md

### Code structure

```
contracts/
- LandNFT.sol
    - TextureLib.sol   //This can be swapped out for texture packs
- WorldEvents.sol
    - UserQueue.sol
    - RandomEventQueue.sol
    - QueueManager.sol
        - QueueDispatcher.sol
            - RandomOracle.sol  // can be swapped out for other oracles
            - Shuffler.sol  //randomizes the queue based on random number
            - Timelocks.sol
                - QueueState.sol

        - QueueProcesser.sol
            - UpdateLookups.sol // list of what each random number applied to what type of square will do
                - QueueState.sol
    - WorldState.sol
- Admin.sol
    - Updater.sol
    - Minter.sol
        - VendingMachine.sol
```

### Content

Goal for 10 different animals/plants for initial launch
1. **Red fruit plant** Grows a red fruit over time
2. **Red bird** Eats red fruit and poops out seeds sometimes
3. **Snails** Eat mushrooms which grow on red fruit that doesn't get eaten
4. **Mushrooms** grow on red fruit if it doesn't get eaten and falls to the ground
5. **Blue Orchids** grow on snail poop
6. **Tall grass** Where snails and rabbits or small animals spawn
7. **Rabbits** Spawn in and eat tall grass
8. **Foxes** Eat rabbits and birds
9. **Butterflies** Purpley, attracted to blue orchids. Birds eat them
10.  
