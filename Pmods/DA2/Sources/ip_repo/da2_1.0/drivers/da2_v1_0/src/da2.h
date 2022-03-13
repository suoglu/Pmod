/* ------------------------------------------------ *
 * Title       : Pmod DA2 Software Driver           *
 * Project     : Pmod DA2 interface                 *
 * ------------------------------------------------ *
 * File        : da2.h                              *
 * Author      : Yigit Suoglu                       *
 * Last Edit   : 28/02/2022                         *
 * ------------------------------------------------ *
 * Description : DA2 Software driver                *
 * ------------------------------------------------ */

#ifndef DA2_H
#define DA2_H

class da2{
public:
  da2(unsigned long baseAddr);

  enum PDMode : unsigned char{
    normalOp = 0,
    gnd1k    = 1,
    gnd100k  = 2,
    highZ    = 3,
    unknown  = 0xCEu //channel error
  };

  unsigned char getStatus();
  unsigned char getConfig();
  void setConfig(unsigned char configNew);
  bool writeChannel(unsigned short value, unsigned char channel);
  void writeChannel(unsigned short value, bool baseChannel = true);
  bool chPDMode(PDMode mode, unsigned char channel);
  void chPDMode(PDMode mode, bool baseChannel = true);
  bool chPDMode(unsigned char value, unsigned char channel);
  void chPDMode(unsigned char value, bool baseChannel = true);
  bool inDualMode();
  bool isBusy();
  bool isValid();
  bool isFastRefresh(bool hard = false);
  bool isBufferingMode();
  PDMode powerDownMode(unsigned char channel);
  PDMode powerDownMode(bool baseChannel = true);
  unsigned char readPDMode(unsigned char channel);
  unsigned char readPDMode(bool baseChannel = true);
  unsigned short readChannel(unsigned char channel);
  unsigned short readChannel(bool baseChannel = true);
  void setBuffering(bool enabled = true);
  void setFastRefresh(bool enabled = true);
  void update(bool fast = false);
  
private:
    //? Use array for channels?
    unsigned long* ch0;
    unsigned long* ch1;
    volatile unsigned long* status;
    volatile unsigned long* config;
};

#endif // DA2_H
