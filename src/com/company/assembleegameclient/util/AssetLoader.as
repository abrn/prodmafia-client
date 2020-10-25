package com.company.assembleegameclient.util {
import com.company.assembleegameclient.map.GroundLibrary;
import com.company.assembleegameclient.map.RegionLibrary;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.objects.particles.ParticleLibrary;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.sound.IMusic;
import com.company.assembleegameclient.sound.SFX;
import com.company.assembleegameclient.sound.SoundEffectLibrary;
import com.company.assembleegameclient.ui.options.Options;
import com.company.util.AssetLibrary;

import flash.utils.getQualifiedClassName;

import kabam.rotmg.assets.EmbeddedAssets;
import kabam.rotmg.assets.EmbeddedData;

public class AssetLoader {

    public static var currentXmlIsTesting:Boolean = false;

    public function AssetLoader() {
        music = new MusicProxy();
        super();
    }
    public var music:IMusic;

    public function load():void {
        this.addImages();
        this.addAnimatedCharacters();
        this.addSoundEffects();
        this.parseParticleEffects();
        this.parseGroundFiles();
        this.parseObjectFiles();
        this.parseRegionFiles();
        Parameters.load();
        Options.refreshCursor();
        this.music.load();
        SFX.load();
    }

    private function addImages():void {
        AssetLibrary.addImageSet("lofiChar8x8", new EmbeddedAssets.lofiCharEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiChar16x8", new EmbeddedAssets.lofiCharEmbed().bitmapData, 16, 8);
        AssetLibrary.addImageSet("lofiChar16x16", new EmbeddedAssets.lofiCharEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiChar28x8", new EmbeddedAssets.lofiChar2Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiChar216x8", new EmbeddedAssets.lofiChar2Embed().bitmapData, 16, 8);
        AssetLibrary.addImageSet("lofiChar216x16", new EmbeddedAssets.lofiChar2Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiCharBig", new EmbeddedAssets.lofiCharBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiEnvironment", new EmbeddedAssets.lofiEnvironmentEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiEnvironment2", new EmbeddedAssets.lofiEnvironment2Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiEnvironment3", new EmbeddedAssets.lofiEnvironment3Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiInterface", new EmbeddedAssets.lofiInterfaceEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("redLootBag", new EmbeddedAssets.redLootBagEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiInterfaceBig", new EmbeddedAssets.lofiInterfaceBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiInterface2", new EmbeddedAssets.lofiInterface2Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj", new EmbeddedAssets.lofiObjEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj2", new EmbeddedAssets.lofiObj2Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj3", new EmbeddedAssets.lofiObj3Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj4", new EmbeddedAssets.lofiObj4Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj5", new EmbeddedAssets.lofiObj5Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj5new", new EmbeddedAssets.lofiObj5bEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObj6", new EmbeddedAssets.lofiObj6Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiObjBig", new EmbeddedAssets.lofiObjBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiObj40x40", new EmbeddedAssets.lofiObj40x40Embed().bitmapData, 40, 40);
        AssetLibrary.addImageSet("lofiProjs", new EmbeddedAssets.lofiProjsEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiParticlesShocker", new EmbeddedAssets.lofiParticlesShockerEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiParticlesBeam",new EmbeddedAssets.lofiParticlesBeamEmbed().bitmapData,16,32);
        AssetLibrary.addImageSet("lofiParticlesSkull",new EmbeddedAssets.lofiParticlesSkullEmbed().bitmapData,16,32);
        AssetLibrary.addImageSet("lofiParticlesElectric",new EmbeddedAssets.lofiParticlesElectricEmbed().bitmapData,32,32);
        AssetLibrary.addImageSet("lofiProjsBig", new EmbeddedAssets.lofiProjsBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiParts", new EmbeddedAssets.lofiPartsEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("stars", new EmbeddedAssets.starsEmbed().bitmapData, 5, 5);
        AssetLibrary.addImageSet("textile4x4", new EmbeddedAssets.textile4x4Embed().bitmapData, 4, 4);
        AssetLibrary.addImageSet("textile5x5", new EmbeddedAssets.textile5x5Embed().bitmapData, 5, 5);
        AssetLibrary.addImageSet("textile9x9", new EmbeddedAssets.textile9x9Embed().bitmapData, 9, 9);
        AssetLibrary.addImageSet("textile10x10", new EmbeddedAssets.textile10x10Embed().bitmapData, 10, 10);
        AssetLibrary.addImageSet("inner_mask", new EmbeddedAssets.innerMaskEmbed().bitmapData, 4, 4);
        AssetLibrary.addImageSet("sides_mask", new EmbeddedAssets.sidesMaskEmbed().bitmapData, 4, 4);
        AssetLibrary.addImageSet("outer_mask", new EmbeddedAssets.outerMaskEmbed().bitmapData, 4, 4);
        AssetLibrary.addImageSet("innerP1_mask", new EmbeddedAssets.innerP1MaskEmbed().bitmapData, 4, 4);
        AssetLibrary.addImageSet("innerP2_mask", new EmbeddedAssets.innerP2MaskEmbed().bitmapData, 4, 4);
        AssetLibrary.addImageSet("invisible", new BitmapDataSpy(8, 8, true, 0), 8, 8);
        AssetLibrary.addImageSet("d3LofiObjEmbed", new EmbeddedAssets.d3LofiObjEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("d3LofiObjEmbed16", new EmbeddedAssets.d3LofiObjEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("d3LofiObjBigEmbed", new EmbeddedAssets.d3LofiObjBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("d2LofiObjEmbed", new EmbeddedAssets.d2LofiObjEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("d2LofiObjBigEmbed", new EmbeddedAssets.d2LofiObjBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("d1lofiObjBig", new EmbeddedAssets.d1LofiObjBigEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("cursorsEmbed", new EmbeddedAssets.cursorsEmbed().bitmapData, 32, 32);
        AssetLibrary.addImageSet("mountainTempleObjects8x8", new EmbeddedAssets.mountainTempleObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("mountainTempleObjects16x16", new EmbeddedAssets.mountainTempleObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("oryxHordeObjects8x8", new EmbeddedAssets.oryxHordeObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("oryxHordeObjects16x16", new EmbeddedAssets.oryxHordeObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("battleOryxObjects8x8", new EmbeddedAssets.battleOryxObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("battleOryxObjects16x16", new EmbeddedAssets.battleOryxObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("santaWorkshopObjects8x8", new EmbeddedAssets.santaWorkshopObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("santaWorkshopObjects16x16", new EmbeddedAssets.santaWorkshopObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("parasiteDenObjects8x8", new EmbeddedAssets.parasiteDenObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("parasiteDenObjects16x16", new EmbeddedAssets.parasiteDenObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("stPatricksObjects8x8", new EmbeddedAssets.stPatricksObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("stPatricksObjects16x16", new EmbeddedAssets.stPatricksObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("buffedBunnyObjects8x8", new EmbeddedAssets.buffedBunnyObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("buffedBunnyObjects16x16", new EmbeddedAssets.buffedBunnyObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("theMachineObjects8x8", new EmbeddedAssets.theMachineObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("theMachineObjects16x16", new EmbeddedAssets.theMachineObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("SakuraEnvironment16x16", new EmbeddedAssets.SakuraEnvironment16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("SakuraEnvironment8x8", new EmbeddedAssets.SakuraEnvironment8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("HanamiParts", new EmbeddedAssets.HanamiParts8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("summerNexusObjects8x8", new EmbeddedAssets.summerNexusObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("summerNexusObjects16x16", new EmbeddedAssets.summerNexusObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("autumnNexusObjects8x8", new EmbeddedAssets.autumnNexusObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("autumnNexusObjects16x16", new EmbeddedAssets.autumnNexusObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("xmasNexusObjects8x8", new EmbeddedAssets.xmasNexusObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("xmasNexusObjects16x16", new EmbeddedAssets.xmasNexusObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("epicHiveObjects8x8", new EmbeddedAssets.epicHiveObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("epicHiveObjects16x16", new EmbeddedAssets.epicHiveObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lostHallsObjects8x8", new EmbeddedAssets.lostHallsObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lostHallsObjects16x16", new EmbeddedAssets.lostHallsObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("cnidarianReefObjects8x8", new EmbeddedAssets.cnidarianReefObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("cnidarianReefObjects16x16", new EmbeddedAssets.cnidarianReefObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("magicWoodsObjects8x8", new EmbeddedAssets.magicWoodsObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("magicWoodsObjects16x16", new EmbeddedAssets.magicWoodsObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("secludedThicketObjects8x8", new EmbeddedAssets.secludedThicketObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("secludedThicketObjects16x16", new EmbeddedAssets.secludedThicketObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lofiGravestone8x8", new EmbeddedAssets.lofiGravestoneEmbed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lofiGravestone16x8", new EmbeddedAssets.lofiGravestoneEmbed().bitmapData, 16, 8);
        AssetLibrary.addImageSet("lofiGravestone16x16", new EmbeddedAssets.lofiGravestoneEmbed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("cursedLibraryObjects8x8", new EmbeddedAssets.cursedLibraryObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("cursedLibraryObjects16x16", new EmbeddedAssets.cursedLibraryObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lairOfDraconisObjects8x8", new EmbeddedAssets.lairOfDraconisObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lairOfDraconisObjects16x16", new EmbeddedAssets.lairOfDraconisObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("lairOfShaitanObjects8x8", new EmbeddedAssets.lairOfShaitanObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("lairOfShaitanObjects16x16", new EmbeddedAssets.lairOfShaitanObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("alienInvasionObjects8x8", new EmbeddedAssets.alienInvasionObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("alienInvasionObjects16x16", new EmbeddedAssets.alienInvasionObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("crystalCaveObjects8x8", new EmbeddedAssets.crystalCaveObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("crystalCaveObjects16x16", new EmbeddedAssets.crystalCaveObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("fungalCavernObjects8x8", new EmbeddedAssets.fungalCavernObjects8x8Embed().bitmapData, 8, 8);
        AssetLibrary.addImageSet("fungalCavernObjects16x16", new EmbeddedAssets.fungalCavernObjects16x16Embed().bitmapData, 16, 16);
        AssetLibrary.addImageSet("innerWorkingsObjects8x8",new EmbeddedAssets.innerWorkingsObjects8x8Embed().bitmapData,8,8);
        AssetLibrary.addImageSet("innerWorkingsObjects16x16",new EmbeddedAssets.innerWorkingsObjects16x16Embed().bitmapData,16,16);
        AssetLibrary.addImageSet("lofiparticlesMusicNotes",new EmbeddedAssets.lofiParticlesMusicNotesEmbed().bitmapData,16,16);
        AssetLibrary.addImageSet("oryxSanctuaryObjects8x8",new EmbeddedAssets.oryxSanctuaryObjects8x8Embed().bitmapData,8,8);
        AssetLibrary.addImageSet("oryxSanctuaryObjects16x16",new EmbeddedAssets.oryxSanctuaryObjects16x16Embed().bitmapData,16,16);
        AssetLibrary.addImageSet("oryxSanctuaryObjects32x32",new EmbeddedAssets.oryxSanctuaryObjects32x32Embed().bitmapData,32,32);
        AssetLibrary.addImageSet("lofiParticlesHolyBeam",new EmbeddedAssets.lofiParticlesHolyBeamEmbed().bitmapData,16,32);
        AssetLibrary.addImageSet("lofiParticlesMeteor",new EmbeddedAssets.lofiParticlesMeteorEmbed().bitmapData,32,32);
        AssetLibrary.addImageSet("lofiParticlesTelegraph",new EmbeddedAssets.lofiParticlesTelegraphEmbed().bitmapData,32,32);
        AssetLibrary.addImageSet("archbishopObjects8x8",new EmbeddedAssets.archbishopObjects8x8Embed().bitmapData,8,8);
        AssetLibrary.addImageSet("archbishopObjects16x16",new EmbeddedAssets.archbishopObjects16x16Embed().bitmapData,16,16);
        AssetLibrary.addImageSet("archbishopObjects64x64",new EmbeddedAssets.archbishopObjects64x64Embed().bitmapData,64,64);
    }

    private function addAnimatedCharacters():void {
        AnimatedChars.add("chars8x8rBeach", new EmbeddedAssets.chars8x8rBeachEmbed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8dBeach", new EmbeddedAssets.chars8x8dBeachEmbed().bitmapData, null, 8, 8, 56, 8, 2);
        AnimatedChars.add("chars8x8rLow1", new EmbeddedAssets.chars8x8rLow1Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rLow2", new EmbeddedAssets.chars8x8rLow2Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rMid", new EmbeddedAssets.chars8x8rMidEmbed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rMid2", new EmbeddedAssets.chars8x8rMid2Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rHigh", new EmbeddedAssets.chars8x8rHighEmbed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rHero1", new EmbeddedAssets.chars8x8rHero1Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rHero2", new EmbeddedAssets.chars8x8rHero2Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8dHero1", new EmbeddedAssets.chars8x8dHero1Embed().bitmapData, null, 8, 8, 56, 8, 2);
        AnimatedChars.add("chars16x16dMountains1", new EmbeddedAssets.chars16x16dMountains1Embed().bitmapData, null, 16, 16, 112, 16, 2);
        AnimatedChars.add("chars16x16dMountains2", new EmbeddedAssets.chars16x16dMountains2Embed().bitmapData, null, 16, 16, 112, 16, 2);
        AnimatedChars.add("chars8x8dEncounters", new EmbeddedAssets.chars8x8dEncountersEmbed().bitmapData, null, 8, 8, 56, 8, 2);
        AnimatedChars.add("chars8x8rEncounters", new EmbeddedAssets.chars8x8rEncountersEmbed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars16x8dEncounters", new EmbeddedAssets.chars16x8dEncountersEmbed().bitmapData, null, 16, 8, 112, 8, 2);
        AnimatedChars.add("chars16x8rEncounters", new EmbeddedAssets.chars16x8rEncountersEmbed().bitmapData, null, 16, 8, 112, 8, 2);
        AnimatedChars.add("chars16x16dEncounters", new EmbeddedAssets.chars16x16dEncountersEmbed().bitmapData, null, 16, 16, 112, 16, 2);
        AnimatedChars.add("chars16x16dEncounters2", new EmbeddedAssets.chars16x16dEncounters2Embed().bitmapData, null, 16, 16, 112, 16, 2);
        AnimatedChars.add("chars16x16rEncounters", new EmbeddedAssets.chars16x16rEncountersEmbed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("d3Chars8x8rEmbed", new EmbeddedAssets.d3Chars8x8rEmbed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("d3Chars16x16rEmbed", new EmbeddedAssets.d3Chars16x16rEmbed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("players", new EmbeddedAssets.playersEmbed().bitmapData, new EmbeddedAssets.playersMaskEmbed().bitmapData, 8, 8, 56, 24, 0);
        AnimatedChars.add("playerskins", new EmbeddedAssets.playersSkinsEmbed().bitmapData, new EmbeddedAssets.playersSkinsMaskEmbed().bitmapData, 8, 8, 56, 24, 0);
        AnimatedChars.add("chars8x8rPets1", new EmbeddedAssets.chars8x8rPets1Embed().bitmapData, new EmbeddedAssets.chars8x8rPets1MaskEmbed().bitmapData, 8, 8, 56, 8, 0);
        AnimatedChars.add("chars8x8rPets2", new EmbeddedAssets.chars8x8rPets2Embed().bitmapData, new EmbeddedAssets.chars8x8rPets1MaskEmbed().bitmapData, 8, 8, 56, 8, 0);
        AnimatedChars.add("petsDivine", new EmbeddedAssets.petsDivineEmbed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("playerskins16", new EmbeddedAssets.playersSkins16Embed().bitmapData, new EmbeddedAssets.playersSkins16MaskEmbed().bitmapData, 16, 16, 112, 48, 0);
        AnimatedChars.add("d1chars16x16r", new EmbeddedAssets.d1Chars16x16rEmbed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("parasiteDenChars8x8", new EmbeddedAssets.parasiteDenChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("parasiteDenChars16x16", new EmbeddedAssets.parasiteDenChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("stPatricksChars8x8", new EmbeddedAssets.stPatricksChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("stPatricksChars16x16", new EmbeddedAssets.stPatricksChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("buffedBunnyChars16x16", new EmbeddedAssets.buffedBunnyChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("theMachineChars8x8", new EmbeddedAssets.theMachineChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("theMachineChars16x16", new EmbeddedAssets.theMachineChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("theGoldenArcher", new EmbeddedAssets.theGoldenArcherEmbed().bitmapData, new EmbeddedAssets.theGoldenArcherMaskEmbed().bitmapData, 8, 8, 56, 24, 0);
        AnimatedChars.add("mountainTempleChars8x8", new EmbeddedAssets.mountainTempleChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("mountainTempleChars16x16", new EmbeddedAssets.mountainTempleChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("oryxHordeChars8x8", new EmbeddedAssets.oryxHordeChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("oryxHordeChars16x16", new EmbeddedAssets.oryxHordeChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("battleOryxChars8x8", new EmbeddedAssets.battleOryxChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("battleOryxChars16x16", new EmbeddedAssets.battleOryxChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("santaWorkshopChars8x8", new EmbeddedAssets.santaWorkshopChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("santaWorkshopChars16x16", new EmbeddedAssets.santaWorkshopChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("Hanami8x8chars", new EmbeddedAssets.Hanami8x8charsEmbed().bitmapData, null, 8, 8, 64, 8, 0);
        AnimatedChars.add("summerNexusChars8x8", new EmbeddedAssets.summerNexusChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("summerNexusChars16x16", new EmbeddedAssets.summerNexusChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("autumnNexusChars16x16", new EmbeddedAssets.autumnNexusChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("autumnNexusChars8x8", new EmbeddedAssets.autumnNexusChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("xmasNexusChars8x8", new EmbeddedAssets.xmasNexusChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("xmasNexusChars16x16", new EmbeddedAssets.xmasNexusChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("epicHiveChars8x8", new EmbeddedAssets.epicHiveChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("epicHiveChars16x16", new EmbeddedAssets.epicHiveChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("lostHallsChars16x16", new EmbeddedAssets.lostHallsChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("lostHallsChars8x8", new EmbeddedAssets.lostHallsChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("magicWoodsChars8x8", new EmbeddedAssets.magicWoodsChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("magicWoodsChars16x16", new EmbeddedAssets.magicWoodsChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("secludedThicketChars8x8", new EmbeddedAssets.secludedThicketChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("secludedThicketChars16x16", new EmbeddedAssets.secludedThicketChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("cursedLibraryChars8x8", new EmbeddedAssets.cursedLibraryChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("cursedLibraryChars16x16", new EmbeddedAssets.cursedLibraryChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("cursedLibraryCharsAvalon16x16", new EmbeddedAssets.cursedLibraryCharsAvalon16x16Embed().bitmapData, null, 16, 16, 112, 48, 0);
        AnimatedChars.add("lairOfDraconisChars8x8", new EmbeddedAssets.lairOfDraconisChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("lairOfDraconisChars16x16", new EmbeddedAssets.lairOfDraconisChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("lairOfShaitanChars16x16", new EmbeddedAssets.lairOfShaitanChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("alienInvasionChars8x8", new EmbeddedAssets.alienInvasionChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("alienInvasionChars16x16", new EmbeddedAssets.alienInvasionChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("fungalCavernChars8x8", new EmbeddedAssets.fungalCavernChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("fungalCavernChars16x16", new EmbeddedAssets.fungalCavernChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("crystalCaveChars8x8", new EmbeddedAssets.crystalCaveChars8x8Embed().bitmapData, null, 8, 8, 56, 8, 0);
        AnimatedChars.add("crystalCaveChars16x16", new EmbeddedAssets.crystalCaveChars16x16Embed().bitmapData, null, 16, 16, 112, 16, 0);
        AnimatedChars.add("innerWorkingsChars8x8",new EmbeddedAssets.innerWorkingsChars8x8Embed().bitmapData,null,8,8,56,8,0);
        AnimatedChars.add("innerWorkingsChars16x16",new EmbeddedAssets.innerWorkingsChars16x16Embed().bitmapData,null,16,16,112,16,0);
        AnimatedChars.add("oryxSanctuaryChars8x8",new EmbeddedAssets.oryxSanctuaryChars8x8Embed().bitmapData,null,8,8,56,8,0);
        AnimatedChars.add("oryxSanctuaryChars16x16",new EmbeddedAssets.oryxSanctuaryChars16x16Embed().bitmapData,null,16,16,112,16,0);
        AnimatedChars.add("oryxSanctuaryChars32x32",new EmbeddedAssets.oryxSanctuaryChars32x32Embed().bitmapData,null,32,32,224,32,0);
        AnimatedChars.add("archbishopChars8x8",new EmbeddedAssets.archbishopChars8x8Embed().bitmapData,null,8,8,56,8,0);
        AnimatedChars.add("archbishopChars16x16",new EmbeddedAssets.archbishopChars16x16Embed().bitmapData,null,16,16,112,16,0);
    }

    private function addSoundEffects():void {
        SoundEffectLibrary.load("button_click");
        SoundEffectLibrary.load("death_screen");
        SoundEffectLibrary.load("enter_realm");
        SoundEffectLibrary.load("error");
        SoundEffectLibrary.load("inventory_move_item");
        SoundEffectLibrary.load("level_up");
        SoundEffectLibrary.load("loot_appears");
        SoundEffectLibrary.load("no_mana");
        SoundEffectLibrary.load("use_key");
        SoundEffectLibrary.load("use_potion");
    }

    private function parseParticleEffects():void {
        var _local1:XML = XML(new EmbeddedAssets.particlesEmbed());
        ParticleLibrary.parseFromXML(_local1);
    }

    private function parseGroundFiles():void {
        var _local1:* = undefined;
        var _local3:int = 0;
        var _local2:* = EmbeddedData.groundFiles;
        for each(_local1 in EmbeddedData.groundFiles) {
            GroundLibrary.parseFromXML(XML(_local1));
        }
    }

    private function parseObjectFiles():void {
        var _local3:* = undefined;
        var _local2:int = 0;
        var _local1:int = 0;
        while (_local2 < 25) {
            currentXmlIsTesting = this.checkIsTestingXML(EmbeddedData.objectFiles[_local2]);
            ObjectLibrary.parseFromXML(XML(EmbeddedData.objectFiles[_local2]));
            _local2++;
        }
        while (_local1 < EmbeddedData.objectFiles.length) {
            ObjectLibrary.parseDungeonXML(getQualifiedClassName(EmbeddedData.objectFiles[_local1]), XML(EmbeddedData.objectFiles[_local1]));
            _local1++;
        }
        ObjectLibrary.parseFromXML(XML(EmbeddedData.objectFiles[_local2]));
        currentXmlIsTesting = false;
        var _local5:int = 0;
        var _local4:* = EmbeddedData.objectPatchFiles;
        for each(_local3 in EmbeddedData.objectPatchFiles) {
            ObjectLibrary.parsePatchXML(XML(_local3));
        }
    }

    private function parseRegionFiles():void {
        var _local1:* = undefined;
        var _local3:int = 0;
        var _local2:* = EmbeddedData.regionFiles;
        for each(_local1 in EmbeddedData.regionFiles) {
            RegionLibrary.parseFromXML(XML(_local1));
        }
    }

    private function checkIsTestingXML(_arg_1:*):Boolean {
        return getQualifiedClassName(_arg_1).indexOf("TestingCXML", 33) != -1;
    }
}
}
