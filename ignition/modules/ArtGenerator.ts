import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre from "hardhat";
import backgrounds from "../../data/backgrounds.json";

import bubble from "../../data/bubble.json";
import tentacle from "../../data/tentacle.json";
import weed from "../../data/weed.json";
import bell from "../../data/bell.json" ;

const ArtGeneratorModule = buildModule("ArtGeneratorModule", (m) => {

  const JelliExtension = m.contract("JelliExtension");

  m.call(JelliExtension, 'setBells', [bell]);
  m.call(JelliExtension, 'setTentacles', [tentacle]);
  m.call(JelliExtension, 'setBubbles', [bubble]);
  
   const ArtGenerator = m.contract("ArtGenerator");
  for(var i = 0; i < backgrounds.length; i++){
    m.call(ArtGenerator, 'insertBackgroundIcon', [backgrounds[i],4], {id: `ArtBackgrounds_${i}_level4`});
    m.call(ArtGenerator, 'insertBackgroundIcon', [backgrounds[i],3], {id: `ArtBackgrounds_${i}_level3`});
    m.call(ArtGenerator, 'insertBackgroundIcon', [backgrounds[i],2], {id: `ArtBackgrounds_${i}_level2`});
  }

    // Update this address from the deployment
  m.call(ArtGenerator, 'setJelliExtension', [JelliExtension]);
  m.call(ArtGenerator, 'setFungi', ['0x7d9CE55D54FF3FEddb611fC63fF63ec01F26D15F']);
  
  const MidiGenerator = m.contract("MidiGenerator");
  const Midi = m.contract("Midi");

  m.call(Midi, "setArtGenerator", [ArtGenerator]);
  m.call(Midi, "setMidiGenerator", [MidiGenerator]);
  //This address needs to be the same as the uniswap pool. Replace for production
  m.call(Midi, "launch", ["0x88A78C5035BdC8C9A8bb5c029e6cfCDD14B822FE"]); 

  return { ArtGenerator };
});

export default ArtGeneratorModule;
