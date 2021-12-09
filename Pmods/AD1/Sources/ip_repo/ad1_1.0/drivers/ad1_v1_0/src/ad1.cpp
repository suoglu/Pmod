/* ------------------------------------------------ *
 * Title       : Pmod AD1 Software Driver           *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : ad1_v1_0.v                         *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 10/12/2021                         *
 * ------------------------------------------------ *
 * Description : AD1 Software driver                *
 * ------------------------------------------------ */

#include "ad1.h"


ad1::ad1(unsigned long baseAddr):
ch0(reinterpret_cast<unsigned long*>(baseAddr)),
ch1(reinterpret_cast<unsigned long*>(baseAddr+4)),
status(reinterpret_cast<unsigned long*>(baseAddr+8)),
config(reinterpret_cast<unsigned long*>(baseAddr+12))
{}

unsigned char ad1::getStatus(){
  return static_cast<unsigned char>(*status);
}

unsigned char ad1::getConfig(){
  return static_cast<unsigned char>(*config);
}

void ad1::setConfig(unsigned char configNew){
  *config = configNew;
}

unsigned short ad1::measure(unsigned char channel){
  switch (channel){
  case 0:
    return measure(true);
  case 1:
    return measure(false);
  default:
    return 0xCe33u; //Channel error
  }
}

unsigned short ad1::measure(bool baseChannel){
  if(baseChannel){
    return static_cast<unsigned short>(*ch0);
  }else{
    return static_cast<unsigned short>(*ch1);
  }
}

void ad1::startMeasurement(unsigned char channel){
  switch (channel){
  case 0:
    return startMeasurement(true);
  case 1:
    return startMeasurement(false);
  }
}

void ad1::startMeasurement(bool baseChannel){
  if(baseChannel){
    *ch0 = 0x0u;
  }else{
    *ch1 = 0x0u;
  }
}

bool ad1::inDualMode(){
  return ((getStatus() & 0x2u) == 0x2u);
}

bool ad1::isBusy(){
  return ((getStatus() & 0x1u) == 0x1u);
}

bool ad1::isBlockingRead(){
  return ((getConfig() & 0x1u) == 0x1u);
}

bool ad1::isUpdatingBoth(){
  return ((getConfig() & 0x2u) == 0x2u);
}

void ad1::setBlockingRead(bool blocking){
  unsigned long configNew = getConfig() & ~0x1u;
  if(blocking){
    configNew|=0x1u;
  }
  setConfig(configNew);
}

void ad1::setUpdatingBoth(bool updateBoth){
  unsigned long configNew = getConfig() & ~0x2u;
  if(updateBoth){
    configNew|=0x2u;
  }
  setConfig(configNew);
}
