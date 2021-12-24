/* ------------------------------------------------ *
 * Title       : Pmod DPOT Software Driver          *
 * Project     : Pmod DPOT interface                *
 * ------------------------------------------------ *
 * File        : dpot.h                             *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 24/12/2021                         *
 * ------------------------------------------------ *
 * Description : DPOT Software driver               *
 * ------------------------------------------------ */
#ifndef DPOT_H
#define DPOT_H

class dpot{
  private:
    unsigned long* resistorPTR;
  public:
    explicit dpot(unsigned long baseAddress);
    dpot(const dpot & old);
    void set(unsigned char newVal);
    unsigned char get();
    unsigned long getAddress();
  };

#endif // DPOT_H
