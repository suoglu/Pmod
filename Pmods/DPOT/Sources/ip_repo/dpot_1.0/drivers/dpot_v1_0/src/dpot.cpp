/* ------------------------------------------------ *
 * Title       : Pmod DPOT Software Driver          *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : dpot.cpp                           *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 24/12/2021                         *
 * ------------------------------------------------ *
 * Description : DPOT Software driver               *
 * ------------------------------------------------ */
#include "dpot.h"

dpot::dpot(unsigned long baseAddress):
resistorPTR(reinterpret_cast<unsigned long*>(baseAddress)){}

dpot::dpot(const dpot &old):
resistorPTR(old.resistorPTR){}

void dpot::set(unsigned char newVal){
  *resistorPTR = static_cast<unsigned long>(newVal);
}

unsigned char dpot::get(){
  return static_cast<unsigned char>(*resistorPTR);
}

unsigned long dpot::getAddress(){
  return reinterpret_cast<unsigned long>(resistorPTR);
}
