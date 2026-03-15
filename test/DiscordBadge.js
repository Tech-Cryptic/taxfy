const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DiscordBadge", function () {

    async function deployBadgeFixture() {
        const [admin, user] = await ethers.getSigners();

        const Badge = await ethers. getContractFactory("DiscordBadge");
        const badge = await Badge.deploy();

        return { badge, admin, user };  
    }

    it("Should set the deployer as admin", async function () {
        const { badge, admin } = await deployBadgeFixture();
        expect(await badge.admin()).to.equal(admin.address);
    });

    it("Should allow admin to mint a badge", async function () {
        const { badge, user } = await deployBadgeFixture();

        await badge.mintBadge(user.address, "TaskFi Early User");
        expect(await badge.balanceOf(user.address)).to.equal(1);
    });
    it("Should not allow non-admin to mint a badge", async function () {
        const { badge, user } = await deployBadgeFixture();

        await expect(
            badge.connect(user).mintBadge(user.address, "Fake Badge")
    ).to.be.revertedWith("Only admin can call this");
    });

    it("should store the correct badge type", async function () {
    const { badge, user } = await deployBadgeFixture();

    await badge.mintBadge(user.address, "Verified Freelancer");

    expect(await badge.getBadgeType(0)).to.equal("Verified Freelancer");
    });

})