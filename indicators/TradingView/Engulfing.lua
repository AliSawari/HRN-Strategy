//@version=5
indicator("Engulfing - Bearish", shorttitle = "Engulfing - Bear", overlay=true)

C_DownTrend = true
C_UpTrend = true
var trendRule1 = "HRN"
var trendRule = input.string("HRN", "Detect Trend Based On", options=[trendRule1, "No detection"])

ma8 = ta.sma(close, 8)
ma20 = ta.sma(close, 20)
ma50 = ta.sma(close, 50)

C_DownTrend := (ma8 < ma20) and (ma20 < ma50)
C_UpTrend := (ma8 > ma20) and (ma20 > ma50)


C_Len = 14 // ta.ema depth for bodyAvg
C_ShadowPercent = 5.0 // size of shadows
C_ShadowEqualsPercent = 100.0
C_DojiBodyPercent = 5.0
C_Factor = 2.0 // shows the number of times the shadow dominates the candlestick body

C_BodyHi = math.max(close, open)
C_BodyLo = math.min(close, open)
C_Body = C_BodyHi - C_BodyLo
C_BodyAvg = ta.ema(C_Body, C_Len)
C_SmallBody = C_Body < C_BodyAvg
C_LongBody = C_Body > C_BodyAvg
C_UpShadow = high - C_BodyHi
C_DnShadow = C_BodyLo - low
C_HasUpShadow = C_UpShadow > C_ShadowPercent / 100 * C_Body
C_HasDnShadow = C_DnShadow > C_ShadowPercent / 100 * C_Body
C_WhiteBody = open < close
C_BlackBody = open > close
C_Range = high-low
C_IsInsideBar = C_BodyHi[1] > C_BodyHi and C_BodyLo[1] < C_BodyLo
C_BodyMiddle = C_Body / 2 + C_BodyLo
C_ShadowEquals = C_UpShadow == C_DnShadow or (math.abs(C_UpShadow - C_DnShadow) / C_DnShadow * 100) < C_ShadowEqualsPercent and (math.abs(C_DnShadow - C_UpShadow) / C_UpShadow * 100) < C_ShadowEqualsPercent
C_IsDojiBody = C_Range > 0 and C_Body <= C_Range * C_DojiBodyPercent / 100
C_Doji = C_IsDojiBody and C_ShadowEquals

patternLabelPosLow = low - (ta.atr(30) * 0.6)
patternLabelPosHigh = high + (ta.atr(30) * 0.6)

label_color_bearish = input(color.red, "Label Color Bearish")
label_color_bullish = input(color.blue, "Label Color Bullish")


C_EngulfingBearishNumberOfCandles = 2

C_EngulfingBearish = C_DownTrend and C_BlackBody and C_WhiteBody[1] and close < open[1] and open > close[1] and high > high[1] and low < low[1]

C_EngulfingBullish = C_UpTrend and C_WhiteBody and C_BlackBody[1] and close > open[1] and open < close[1] and high > high[1] and low < low[1]



alertcondition(C_EngulfingBearish, title = "New pattern detected", message = "New Engulfing – Bearish pattern detected")
if C_EngulfingBearish
    var ttBearishEngulfing = "Bearish Engulfing"
    label.new(bar_index, patternLabelPosHigh, text="BE", style=label.style_label_down, color = label_color_bearish, textcolor=color.white, tooltip = ttBearishEngulfing)
bgcolor(ta.highest(C_EngulfingBearish?1:0, C_EngulfingBearishNumberOfCandles)!=0 ? color.new(color.red, 90) : na, offset=-(C_EngulfingBearishNumberOfCandles-1))


alertcondition(C_EngulfingBullish, title = "New pattern detected", message = "New Engulfing – Bullish pattern detected")
if C_EngulfingBullish
    var ttBearishEngulfing = "Bullish Engulfing"
    label.new(bar_index, patternLabelPosLow, text="BE", style=label.style_label_up, color = label_color_bullish, textcolor=color.white, tooltip = ttBearishEngulfing)
bgcolor(ta.lowest(C_EngulfingBullish?1:0, C_EngulfingBearishNumberOfCandles)!=0 ? color.new(color.blue, 90) : na, offset=-(C_EngulfingBearishNumberOfCandles-1))
