/* ------------------------------------------------ *
 * Title       : Pmod DA2 Software Driver           *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : da2.cpp                            *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 28/02/2022                         *
 * ------------------------------------------------ *
 * Description : DA2 Software driver                *
 * ------------------------------------------------ */

#include "da2.h"


da2::da2(unsigned long baseAddr):
ch0(reinterpret_cast<unsigned long*>(baseAddr)),
ch1(reinterpret_cast<unsigned long*>(baseAddr+4)),
status(reinterpret_cast<unsigned long*>(baseAddr+8)),
config(reinterpret_cast<unsigned long*>(baseAddr+12))
{}

unsigned char da2::getStatus(){
  return static_cast<unsigned char>(*status);
}

unsigned char da2::getConfig(){
  return static_cast<unsigned char>(*config);
}

void da2::setConfig(unsigned char configNew){
  *config = configNew;
}

bool da2::writeChannel(unsigned short value, unsigned char channel){
  switch(channel){
  case 0:
    writeChannel(value, true);
    break;
  case 1:
    writeChannel(value, false);
    break;
  default:
    return false;
  }
  return true;
}

void da2::writeChannel(unsigned short value, bool baseChannel){
  if(baseChannel){
    *ch0 = value;
  }else{
    *ch1 = value;
  }
}

bool da2::chPDMode(da2::PDMode mode, unsigned char channel){
  return chPDMode(static_cast<unsigned char>(mode), channel);
}

void da2::chPDMode(da2::PDMode mode, bool baseChannel){
  chPDMode(static_cast<unsigned char>(mode), baseChannel);
}

bool da2::chPDMode(unsigned char value, unsigned char channel){
  switch(channel){
  case 0:
    chPDMode(value, true);
    break;
  case 1:
    chPDMode(value, false);
    break;
  default:
    return false;
  }
  return true;
}

void da2::chPDMode(unsigned char value, bool baseChannel){
  unsigned char valueClean = value & 0x3u;
  if(baseChannel){
    setConfig((~0x0Cu & getConfig())|(valueClean<<2));
  }else{
    setConfig((~0x30u & getConfig())|(valueClean<<4));
  }
}

bool da2::inDualMode(){
  return getStatus() & 0x4u;
}

bool da2::isBusy(){
  return getStatus() & 0x1u;
}

bool da2::isInvalid(){
  return getStatus() & 0x2u;
}

bool da2::isFastRefresh(bool hard){
  if(hard){
    return getStatus() & 0x8u;
  }else{
    return getConfig() & 0x40u;
  }
}

bool da2::isBufferingMode(){
  return getConfig() & 0x1u;
}

da2::PDMode da2::powerDownMode(unsigned char channel){
  return static_cast<PDMode>(readPDMode(channel));
}

da2::PDMode da2::powerDownMode(bool baseChannel){
  return static_cast<PDMode>(readPDMode(baseChannel));
}

unsigned char da2::readPDMode(unsigned char channel){
  switch(channel){
  case 0:
    return readPDMode(true);
    break;
  case 1:
    return readPDMode(false);
    break;
  default:
    return 0xC3u;
  }
}

unsigned char da2::readPDMode(bool baseChannel){
  if(baseChannel){
    return (getConfig() >> 2) & 0x3u;
  }else{
    return (getConfig() >> 4) & 0x3u;
  }
}

unsigned short da2::readChannel(unsigned char channel){
  switch(channel){
  case 0:
    return readChannel(true);
    break;
  case 1:
    return readChannel(false);
    break;
  default:
    return 0xCe33u; //Channel error
  }
}

unsigned short da2::readChannel(bool baseChannel){
  if(baseChannel){
    return *ch0;
  }else{
    return *ch1;
  }
}

void da2::setBuffering(bool enabled){
  if(enabled){
    setConfig(( 0x1 | getConfig()));
  }else{
    setConfig((~0x1 & getConfig()));
  }
}

void da2::setFastRefresh(bool enabled){
  if(enabled){
    setConfig(( 0x40 | getConfig()));
  }else{
    setConfig((~0x40 & getConfig()));
  }
}

void da2::update(bool fast){
  unsigned char conf = 0x0u;
  if(!fast){
    conf = getConfig();
  }

  setConfig(conf|0x2u);
}
