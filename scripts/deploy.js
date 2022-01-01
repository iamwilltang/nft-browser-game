const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
    
    const gameContract = await gameContractFactory.deploy(
        ["Hiccup", "Percy Jackson", "Hermione"],
        ["https://bit.ly/3mH9K3z",
        "https://i.imgur.com/mAqqAYt.jpeg",
        "https://i.imgur.com/H1xMYFK.jpeg"],
        [200, 250, 200],                        // HP
        [150, 150, 150],                        // Attack Damage
        "Dolores Umbridge",
        "https://i.imgur.com/bXnDf65.jpeg",
        10000,
        50
    );
    
    await gameContract.deployed();
    console.log("Contract deployed to: ", gameContract.address);
    
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
        }
        catch (error) {
            console.log(error);
            process.exit(1);
        }
    };

runMain();