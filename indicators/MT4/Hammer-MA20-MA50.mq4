#property copyright "Created By Ali Sawari"
#property version   "1.00"
#property description ""

#include <stdlib.mqh>
#include <stderror.mqh>

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 5
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy Hammer"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 5
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell Hammer"


//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
extern bool Audible_Alerts = true;
extern bool Push_Notifications = true;
double myPoint; //initialized in OnInit

void myAlert(string type, string message) {
  // int handle;
  const string MSG_LABEL = " | Hammer ";
  if(type == "print") Print(message);
  else if(type == "error") Print(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | "+message);
  else if(type == "indicator") {
    Print(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message );
    if(Audible_Alerts) Alert(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message);

    // handle = FileOpen("Buy Hammer-8 MT4.txt", FILE_TXT|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE, ';');
    // if(handle != INVALID_HANDLE) {
    //   FileSeek(handle, 0, SEEK_END);
    //   FileWrite(handle, type+" | Buy Hammer-8 MT4 @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
    //   FileClose(handle);
    // }

    if(Push_Notifications) SendNotification(type + MSG_LABEL + Symbol() + "," + IntegerToString(Period()) + " | " + message);
  }
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {   
  IndicatorBuffers(2);
  SetIndexBuffer(0, Buffer1);
  SetIndexEmptyValue(0, EMPTY_VALUE);
  SetIndexArrow(0, 241);
  SetIndexBuffer(1, Buffer2);
  SetIndexEmptyValue(1, EMPTY_VALUE);
  SetIndexArrow(1, 242);
  //initialize myPoint
  myPoint = Point();
  if(Digits() == 5 || Digits() == 3){
    myPoint *= 10;
  }
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[]) {
  int limit = rates_total - prev_calculated;
  //--- counting from 0 to rates_total
  ArraySetAsSeries(Buffer1, true);
  ArraySetAsSeries(Buffer2, true);
  //--- initial zero
  if(prev_calculated < 1){
    ArrayInitialize(Buffer1, EMPTY_VALUE);
    ArrayInitialize(Buffer2, EMPTY_VALUE);
  }
  else limit++;
  
  //--- main loop
  for(int i = limit-1; i >= 0; i--) {
    if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation
    // Main MAs & RSI
    float MA20_1 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA20_2 = iMA(NULL, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA50_1 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA50_2 = iMA(NULL, PERIOD_CURRENT, 50, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA200_1 = iMA(NULL, PERIOD_CURRENT, 200, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA200_2 = iMA(NULL, PERIOD_CURRENT, 200, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float RSI = iRSI(NULL, PERIOD_CURRENT, 14, PRICE_CLOSE, 1+i);
    // Approximation MAs for Better PB Detection
    float MA18_1 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA18_2 = iMA(NULL, PERIOD_CURRENT, 18, 0, MODE_SMA, PRICE_CLOSE, i+2);
    float MA48_1 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+1);
    float MA48_2 = iMA(NULL, PERIOD_CURRENT, 48, 0, MODE_SMA, PRICE_CLOSE, i+2);
    // MA comparison & RSI Validation
    bool isUptrend = MA20_1 > MA50_1 && MA50_1 > MA200_1 && MA20_2 > MA50_2 && MA50_2 > MA200_2 && RSI < 70;
    bool isDowntrend = MA20_1 < MA50_1 && MA50_1 < MA200_1 && MA20_2 < MA50_2 && MA50_2 < MA200_2 && RSI > 30;
    // MAs increasing in value
    bool isMAsIncreasing = MA20_1 > MA20_2 && MA50_1 > MA50_2;
    bool isMAsDecreasing = MA20_1 < MA20_2 && MA50_1 < MA50_2;
    // is either of the candles are in contact with the MA (approximation -2), in order to detect a Pullback on the MA
    bool isHitting1 = (MA20_1 <= High[i+1] && MA20_1 >= Low[i+1]) || (MA18_1 <= High[i+1] && MA18_1 >= Low[i+1]);
    bool isHitting2 = (MA20_2 <= High[i+2] && MA20_2 >= Low[i+2]) || (MA18_2 <= High[i+2] && MA18_2 >= Low[i+2]);
    bool isHittingMA20 = isHitting1 || isHitting2;
    bool isHitting3 = (MA50_1 <= High[i+1] && MA50_1 >= Low[i+1]) || (MA48_1 <= High[i+1] && MA48_1 >= Low[i+1]);
    bool isHitting4 = (MA50_2 <= High[i+2] && MA50_2 >= Low[i+2]) || (MA48_2 <= High[i+2] && MA48_2 >= Low[i+2]);
    bool isHittingMA50 = isHitting3 || isHitting4;
    // is Hammer Pattern  Buy
    float upperShadowB = High[i+1] - MathMax(Open[i+1], Close[i+1]);
    float bodyLengthB = MathAbs(Close[i+1] - Open[i+1]);
    float lowerShadowB = MathMin(Open[i+1], Close[i+1]) - Low[i+1];
    float prevUpperShadow = High[i+2] - MathMax(Open[i+2], Close[i+2]);
    float prevBodyLengthB = MathAbs(Close[i+2] - Open[i+2]);
    bool isBodyBiggerThanUpperShadow = bodyLengthB >= upperShadowB;
    bool isLowerShadowTwiceTheBody = lowerShadowB >= (2 * bodyLengthB);
    bool isCloseLowerThan = Close[i+1] < MathMax(Open[i+2], Close[i+2]);
    bool isShadowTrailingBelow = Low[i+1] < Low[i+2];
    bool isPrevNotHammerB = prevBodyLengthB >= prevUpperShadow;
    bool isCloseAboveMA20 = Close[i+1] >= MA20_1;
    bool isCloseAboveMA50 = Close[i+1] >= MA50_1;
    bool isHammerBuy20 = isBodyBiggerThanUpperShadow && isLowerShadowTwiceTheBody && isCloseLowerThan && isShadowTrailingBelow && isPrevNotHammerB && isCloseAboveMA20;
    bool isHammerBuy50 = isBodyBiggerThanUpperShadow && isLowerShadowTwiceTheBody && isCloseLowerThan && isShadowTrailingBelow && isPrevNotHammerB && isCloseAboveMA50;
    // is Hammer Pattern  Sell
    float upperShadowS = High[i+1] - MathMax(Open[i+1], Close[i+1]);
    float bodyLengthS = MathAbs(Close[i+1] - Open[i+1]);
    float lowerShadowS = MathMin(Open[i+1], Close[i+1]) - Low[i+1];
    float prevLowerShadow = MathMin(Open[i+2], Close[i+2]) - Low[i+2];
    float prevBodyLengthS = MathAbs(Close[i+2] - Open[i+2]);
    bool isBodyBiggerThanLowerShadow = bodyLengthS >= lowerShadowS;
    bool isUpperShadowTwiceTheBody = upperShadowS >= (2 * bodyLengthS);
    bool isCloseAboveThan = Close[i+1] > MathMin(Open[i+2], Close[i+2]);
    bool isShadowTrailingAbove = High[i+1] > High[i+2];
    bool isPrevNotHammerS = prevBodyLengthS >= prevLowerShadow;
    bool isCloseBelowMA20 = Close[i+1] <= MA20_1;
    bool isCloseBelowMA50 = Close[i+1] <= MA50_1;
    bool isHammerSell20 = isBodyBiggerThanLowerShadow && isUpperShadowTwiceTheBody && isCloseAboveThan && isShadowTrailingAbove && isPrevNotHammerS && isCloseBelowMA20;
    bool isHammerSell50 = isBodyBiggerThanLowerShadow && isUpperShadowTwiceTheBody && isCloseAboveThan && isShadowTrailingAbove && isPrevNotHammerS && isCloseBelowMA50;



    // final conditions
    bool conditionUptrend20 = isUptrend && isMAsIncreasing && isHittingMA20 && isHammerBuy20;
    bool conditionDowntrend20 = isDowntrend && isMAsDecreasing && isHittingMA20 && isHammerSell20;
    bool conditionUptrend50 = isUptrend && isMAsIncreasing && isHittingMA50 && isHammerBuy50;
    bool conditionDowntrend50 = isDowntrend && isMAsDecreasing && isHittingMA50 && isHammerSell50;

    if(conditionUptrend20 || conditionUptrend50) {
      Buffer1[i] = Low[1+i];
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", conditionUptrend20 ? "Buy Hammer MA20" : "Buy Hammer MA50"); time_alert = Time[0];
    } else Buffer1[i] = EMPTY_VALUE;
    
    if(conditionDowntrend20 || conditionDowntrend50){
      Buffer2[i] = Low[1+i];
      if(i == 0 && Time[0] != time_alert) myAlert("indicator", conditionDowntrend20 ? "Sell Hammer MA20" : "Sell Hammer MA50"); time_alert = Time[0];
    } else Buffer2[i] = EMPTY_VALUE;

  }

  return(rates_total);
}
