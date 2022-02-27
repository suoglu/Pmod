/* ------------------------------------------------ *
 * Title       : Pmod AD1 Software Driver           *
 * Project     : Pmod AD1 interface                 *
 * ------------------------------------------------ *
 * File        : ad1.h                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 10/12/2021                         *
 * ------------------------------------------------ *
 * Description : AD1 Software driver                *
 * ------------------------------------------------ */

#ifndef AD1_H
#define AD1_H

class ad1{
  private:
    //? Use array for channels?
    volatile unsigned long* ch0;
    volatile unsigned long* ch1;
    volatile unsigned long* status;
    unsigned long* config;

  public:
    ad1(unsigned long baseAddr);
    unsigned char getStatus();
    unsigned char getConfig();
    void setConfig(unsigned char configNew);
    unsigned short measure(unsigned char channel);
    unsigned short measure(bool baseChannel = true);
    void startMeasurement(unsigned char channel);
    void startMeasurement(bool baseChannel = true);
    bool inDualMode();
    bool isBusy();
    bool isBlockingRead();
    bool isUpdatingBoth();
    void setBlockingRead(bool blocking = true);
    void setUpdatingBoth(bool updateBoth = true);
};

#endif // AD1_H
