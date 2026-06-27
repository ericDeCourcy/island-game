Plan.md

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