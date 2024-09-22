package require base64

set icons {
PMCode2.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAk0lEQVR4nO2V0Q6AIAhFua3//2V6
crszdUIpc4M3aXJOaARVlci4QukpkAIpkAIicns3AniNUFXFFgEA2oL18sNa1n8BQ7gLnLNImDpQ
ihcwgzhnkXBfwhrgOX+TAL99D8bPW5f0k8CqOEdgpr0zx+QWaMFG6+k60XPALDCCbJmEDKtznlng
FvgrzvkMUyAFUmBVPHVHei8hB6qOAAAAAElFTkSuQmCC}
PMCode6.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAlUlEQVR4nO2VSwrAMAhEndL7X3m6
EiSfEiUfAs7SoPMSjIKknNRz1D0BEiABEkBE3mgigGqEksQWAABsmfXiv7W8u8Ca2FewMQ+EC0CL
q7HNVEc9H4UIN2GJHd2pwwD29j0zSv1K0wBW6R4A21y97oJsbMKyunsCad5Vc6AFMRKfDqBmZSyy
C8IAs3TPN0yABEiAVfoAY3VuKRr74wMAAAAASUVORK5CYII=}
PMCode10.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAnklEQVR4nO2VUQqAMAxDE/H+V45f
lTKnrEUdgxb8cLLmrbUZJWFmbFPVC6AACqAAAOzZjSQvFiqJ4TwZKybZ3cUERLgFXpzuAQChX5nH
fJEKmPgp6E5rwvZ9tBLpn7AVyPQ/BOBPfycmiUSsFdPHcB2AkfKOtCkN0BN7eh/OEzWi1gcs/Fpk
IqY7YQrAINq13+6CN2OdMSyAAiiAr+IAJbhXLAnFUdEAAAAASUVORK5CYII=}
PMCode14.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAn0lEQVR4nO2V4QrAIAiE78be/5Vv
vwppbaSsRaDQn0z9srooCSvtWFo9ARIgARIAwBkNJHmTUEl054lIMcluFAMQ7iOwxWkGAAj9zrzm
83SgFLcFq89CYLwT4UvYYkf/1GEAu/unYtY/ehTLn+E+AJJY2/uwxvqnX8I2u1uBSpxXiFodKGbn
PGK0XAlDAAWinfvtL/jS9nmGCZAACTDLLpifSCys2nE6AAAAAElFTkSuQmCC}
PMCode18.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAArElEQVR4nO2VUQrAMAhD69j9r+y+
BqHYonHgCvavrpg302WiqqNyXaXqDdAAXwCISOozOn8CxwMIm4SW96oq0T43K26JrerbXtEJoAhO
AWsRiNAE3uavMAphLQJBX8JZgPE/BIBvvxLD596AWlqQTTirhwW+BJgPM0AeW9wWeMbrsYkGsMR2
e3ef6hygorg0CVFsrjFZQAMgCBtCY/zgd9wA6TuQXeUTaIBygAf0nZErZBTr4QAAAABJRU5ErkJg
gg==}
PMCode22.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAsUlEQVR4nO2VSw6AMAhEi/H+V8YV
CUFQPkbSBJZoZ56AFBBxdcbR6j4AA/AFAACUfqP9K7A9AGQ3odZ7RISozpk118ys/KNWtALchFeB
5yIQIQASJ2N+khzpuRciPYQSO7sM3AD86y0zXPcqvYU5hNUNp2lobTEB5MsZIM8cuFvAh8tShfXj
EEr18Aaic1vtAQ3Ck/8cgMxkLnMXpAE4SMaYov06HoDyDFSjvQID0A5wAeLLhSXEkGNoAAAAAElF
TkSuQmCC}
PMCode26.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAsklEQVR4nO2VwQrEIAxEZ5b9/1+e
PVmCaEliaVYw4KGtdZ4ZEykJlfEpVT8AB+AJAJJLZbR/BrYHYLYTjryXxFcASA7/YgIibIEVpxkA
IMSrIpSBJn4Jmt024fbdm4n0IewFMv6HAOzuZ2KSSMSs+N4JeuG8a4zApwD95AyQxxa3BZ70emxK
A4zE7p7d60QbUd8HWth3kYoo74R73gU9SLYJAX9wHR+A5TOwGuUZOADlAD+lDm4o2Kc1sAAAAABJ
RU5ErkJggg==}
PMCode30.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAs0lEQVR4nO2VSw6AMAhEGeP9rzyu
aghpDVCVNCmJG/uZV6BTkJTKOErVN8AGeAMAwNQ1Wj8DywMg64S92pPELwAAuquQgAiXQItDfSIi
lPitCGWgiWvBe0xDiD8T6Sa02FkzcAPo04/E9Li3FOeToBfOu0evLEMAOzkD5OkDdwlI4k7vYI4e
/7wJ7e5hB2rrokZkfaCF/hcxo3InXPMtsCAZ4Rblz/EGmO6B2SjPwAYoB7gAGARfKIXf2/QAAAAA
SUVORK5CYII=}
PMCode38.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAlklEQVR4nO2VSw6AMAhEO8b7X3lc
mCrW1hTsJ01gSQLzSqYAkmFmbFPVHcABHMABQgi7tRDAa4WSxBAAAMyJlfKfvbS3QIrIKcicBkIF
EJvfwrIWF4gG4ocJU3DbVa0GeL6+JMbMlBoB9Ip1AJ7mKvkLI02Y9lfvoLNqqT2Qg6jJNweIYmnO
cgvMAK1inW/oAA7gAL3iAFl1bil4TrCyAAAAAElFTkSuQmCC}
PMCode46.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAo0lEQVR4nO2VyQrAMAhEZ0r//5en
hxJi04Vol1BQyCWgPpdMKAkjbRqaPQESIAESAMAcdSS5k1BJdMeJSDHJQy8GINwjsMlpDgAIx525
jOfpQEleS7S+rBDo78SNJWzBY79qN8C2+rNkWqtH/yiGP8P/AEhiaa9dw63xyyVs47s1aPXyClGr
A8XsnUeMhithCKBAtHef/QVP2n+eYQIkQAK8ZQuOn0gsWoYC6AAAAABJRU5ErkJggg==}
PMCode54.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAsElEQVR4nO2V3Q6AIAiFo/X+r0wX
zUIGjh8Xc5NLlpxPOCEg4lEZZ6n6BtgAMwAAIPUbrd+B5QEgugml2SMieOtcUXFJTMsPa3k7QEVo
F2jOA+ECaMU/YXoWXhAPRMKEHDzmJTNAf3tNDIUujUM1YXbDSTWksagA/OMIkMUH5hH05tLqwp8m
5PXdO+g5tdQekCAs+ekATYznIm9BGICCRIRblD/HGyDtgWyUd2ADlAPc2MuFJSHuHP0AAAAASUVO
RK5CYII=}
PMCode62.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAtUlEQVR4nO2V4QqAMAiEvej9X/n6
ESOTFeoiGUzoT2y7T705kJTK2ErVF8AC+AIAwNA1mr8C0wMgOwl7vSeJXwAAdHchARFugRaH+kRE
KPFbEapAE79S1HtxQYi/EgMmtOA5L7kB7tk/ifHMXvyt2N8EvXDeM3pteQSwizNAHh+4W0ASrbza
hvfAnya054dn0LkrOojsHGih/0WGUfkknPMtsCAZ4Rblz/ECGPbAaJRXYAGUAxwOBF8oVUws+AAA
AABJRU5ErkJggg==}
PMCode82.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA5ElEQVR4nO1Wyw7DMAiDaf//y+wU
yaUBDdOJVhq30BQ75pGomcmkvUbR/wSuIKCqrSJ6tgLr9B0VaAKqamamIiJmpiwJmsACj9Y/J3CV
KTsJd5IzKrxZ8B1Y5E9jVRVAEFQBfRUSJQVW8AWMQOirkEiLMGutShdkcUIC/hR4+ggMv/v0RCRO
KcCN3Tnv/9+l7kQgKiaGzE5BvydMQSRjJmeUpixtaRFWCqtSsIf/pucANYpHJyGCeR9zF9AEkAh7
FYvc4DpuvYiy9ddxOinYdUHVWinANyEbY7wG2l3QtXEFxgl8AMx70is7qEYbAAAAAElFTkSuQmCC}
PMCode86.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA8ElEQVR4nO2WwQ4DIQhEmab//8vT
ExuCQlawsZvUm7rCYxx1QVJOttfR7H+AHQAAWiZ6tgJafUeFMgAAkoSICElUIcoAmjzqfx1gV0P1
JpxJXlHhXU0+SxaNp7FWFbBJrAp2bAViCUCDa2K7UjPq/F2I1ITZ0fITWRlZnBDAV2Grj6JRRpVE
8ntiMKH9sHvP+/XX1pnCBoDITBWYmYL+m3ALIhlJInIXZG7CzJSpCTMn+4nM8mmcR90DM4g749sB
NJkfq7wFZQALUn2KRX7gOW79EWX923E6WzA7BauttQX2n7Aa47gH2qeg244rcBzgA7qpxiXzcGze
AAAAAElFTkSuQmCC}
PMCode90.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA7klEQVR4nO1Wyw7DMAizp/3/L3un
RCgPVKBTVmlIPdAo2JhAQkk4aa+j6H8CdxAgWTpEz1agZV9RIU2ApCQRACQxSyJNoIHv/K8TuMuY
nYQryTMqpAiQXO5igkS4BBac5gMAId4RIQUaeAc02Tbgtn5VCVcBL5tIF3hxtgRsn3cffnaSSMyl
8ObE22NbnfPj/l4mk8BEoC2uFIgSmBRcKLctwSjbTl5ruzLtwF0CYwYrMM+/HCc6iMY50EHMv8gw
Oj4Jn3kXjESyVzHwA9dx6UXk+ZfjVEowzolMjFIJ7JswG+P4GSh3QdWOK3CcwAd87K8oU5OwmQAA
AABJRU5ErkJggg==}
PMCode94.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA8ElEQVR4nO1WQQ7DMAizp/3/y95l
qRBLaAKdskpD6oHSYmMSEkrCTntsRf8TuIIAydIiurcCrfqKCmkCJCWJACCJWRJpAg185H+dwFXG
7CTsSZ5RIUWAZPcvJkgst8CC0zwAIKzviCUFGrgFPGKWBOaVCBWIqvGBqIwoz5CA3eeHj3d1AakW
t6DRnPhowVnVEQFYAsE3trDnKNhTIMh5CuTzNRu2wMsmiWfV2fgMeEjAV9ADi/zpPKuDyM+BA8S8
WxlG2yfhPc8CTyR7FAM/cByXbkSRP52n0gI/JzI5Si2wd8Jsju1roLwLqrZdge0EXvUroxxX5/oY
AAAAAElFTkSuQmCC}
PMCode118.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA7klEQVR4nO2W2w4CMQhEGeP///L4
YKrIAtlCTd3EvvUGp9PpBSRlZ7ltzf4HWAEAoGWiayswVt9RoQwAgCQhIkISVYgywEge1b8OsKqg
ehN6kldUuFeTe8mi9jTWrAI6iVZBt81ATAGM4O/Eei5eIDMQqQnzo2W74qFZnBDAruJz9VE8Oirl
98TBhHpg956380ddL+wAEJmpAuMpaMeEWxDJ+AwS+QuuCTNTpibMnWy74qFZnGvdAx7EmfblACOZ
bau8BWUADVJ9ikV+4Dlu/Yiy+uk4nS3wTsFsaW2B/hNWY2z3QPsUdMt2BbYDPACwqcYlKH6ndgAA
AABJRU5ErkJggg==}
PMCode126.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA90lEQVR4nO1WQQ7DMAizp/3/y+yU
ljGgDXTKKi1SDzStbUxCQhHByvFYyv4XcIUAkq1FdG8HRvYdF8oCSIqIEABEhFURZQGDPIq/LuCq
wWon9CyvuFASQNL9iwUR0yXQ5FQPAAjmd8SUA4N8T1H/y10EzjuROpBnY6fiTzOcUIDe51sMnacv
ivgsRdYnPkqQqT0WAADEe5kcHJXYM5r0HEgwD4ks3hhhCaxtIsJhb5wf3UUYkacCbAYeWR6fw5lu
RLYPbCTq3UwzWt4J73kWWCHVoxj4geO4dSPK4tM4nRLYPlHBaJVA3wmrGMvXQHsXdMdyB5YLeAHp
K6McrPwuRQAAAABJRU5ErkJggg==}
PMCode130.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAApUlEQVR4nO2V0Q6AIAhFva3//2V6
YiPSJhSRGzwpbtyjXBVE1DJjS1UvgD8A7NECAE4uJyJ8CqBFAZCcp7egANwe0OZq7WqwMABtpJk8
j/U6rH+BFOkVHkGMwnQCXJyF9fXinAXCbUIt4Om/CUDufiQm13smfQQQFesAzBzvTJvcAD2xu/l0
nex3wAxwJ2IVdwOwmM553gI3wFuxzjUsgAIogKg4AJIxiTFARzSSAAAAAElFTkSuQmCC}
PMCode134.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAApUlEQVR4nO2V0QrAIAhFvWP//8vu
SXA2oSRrgT41I++p7hLMTDvj2qpeAH8AuLMFALxczsxYCmBFAbD+3n4FBRD2gDUXUWuwNABrpJ68
jO08RnuBFvkq7EG49UYApLgI65WiKPO9EGETWuxoT+0G0Lv3xJjaU5oGkBXnAGhzee4CLTShrT78
Asm6o96BL4ie/HQAEbO5SC8IA8yKc37DAiiAAsiKB4BffSv7trbYAAAAAElFTkSuQmCC}
PMCode138.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAqklEQVR4nO2VwQ7DMAhD46n//8ve
ZUiUsTXQpmkkuAWp+AVMCpJtZrymqhfAEwC20QIAdi4niVsBrCgA6vP0ERRA2gPWXK19G6yrTuYp
BuB+BQfiaAvCAFpcV9K5SCdCACIu1e16CUgEIm1CK5CZfwhA3/6XGEmgfbrgmPQUwKhYB6CnvT1j
SgN4Yv/O3XWWegc8iF0+KJ4GEAibu+1fcGWss4YFUAAFMCrepFhrJURIhc8AAAAASUVORK5CYII=}
PMCode142.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAqklEQVR4nO2V0Q6FIAxDqfH/f7n3
CVN3MbopIsn25nDrEcsAyTIylqHqCfAFgLW3AICdy0niVQArCoD6PPwXJEDYA9Zcpfwb7FKfyCgG
0KxCA+LsFLgBVFw7ac6zEy6AKl67a6XmPBBhE1rs6J16GUC//khM11smvQXQK+YBIIltew/e0fXu
JrTd3ROo1k01B1oQu7xTPAxQIWzutbvgyZjnGCZAAiRAr/gBF05cJQ6F/AsAAAAASUVORK5CYII=}
PMCode146.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAwklEQVR4nO2VwQrEMAhEddn//+Xp
SXCtcdVQ7CFCoUmK8+qIYQA0GZ9R9QPwBoDv0wLM/NPlAFivtytgBbwAwPLY78ctOADtJtReyrtt
sMcAmBmeWLQv7/acq3eBFvESryBWUaqAJPdKrvcqEO0mtAId/0sA+u9XYvo8M6CIAguyCaL4N4ZD
gFu3NoAytqQtyJQ3Y1MbwBOL1uk803OgDBCJVMXbACJm9zqzoA2gQbpDiOgF1/EB2O6B3RivwAEY
B7gA8PGhMUC5ruwAAAAASUVORK5CYII=}
PMCode150.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAxElEQVR4nO2V4Q7DIAiEvWXv/8q3
XzSMikVcx5ZI0sRq5b7iRUCyVcajVH0D/ALA824BAG8uJwn9vlwBK9ALkpDHfl9+BBsgbUJ9ljK2
BrsNAAB7YqN5Gdt1zPYCLdJL7EG4+WYAJPlRcr2mQGYg0ia02NmeGgbQf++JsZ2rdBWuCaMJRnF1
DQ8BTm5NAEV8ED4CbS4vK9oXTWizT99Asu+v7oEeRGT+4wAiZucyvSANoEEywhLl7XgDLHtgNcor
sAHKAV7fH5UrJ7NGYwAAAABJRU5ErkJggg==}
PMCode154.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAyElEQVR4nO2V4QrDMAiEvbH3f+Xb
n1msZIka1rQQodCE1vuqVwOSsjJeS9U3wB0A3v8WAHByOUnY9XQFvEArSEIv//zyFmyAsgltL/Xe
GyyUpzKKATTfQgNi9BekAay4zWT3MpVIAai4ZrdCRxuSEGUTeoFK/1MA9ut/iZEE5FuFwIAS6fwF
0QS9GBmwCzBycyQibQm3IFLeSJvKAC2x3jqc51FzoAVx2k+KlwEUwu9ddhZ4kOoQErnBcbwBpj0w
G8srsAGWA3wAAyeDJXP1XVYAAAAASUVORK5CYII=}
PMCode158.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAx0lEQVR4nO2VUQ7EIAhEnc3e/8qz
XzSUWAVMlzaRpEmLCq84Iki2SvuUZt8ATwD43p0AwEnlJKG/lytgE/SMJOSx88u3YAOkRaj3Ut6t
wFxxMq0YQHcVOhCzUxAG0Ml1JO2LVCIEIMklul6pfRGItAgtdvZOdQPov79Kpsc9Daq1wSnwBhjZ
TIBDgJmaPebRgXsLSOIo78UcPX67CG30cAeSda/qAz2Ikz+YPA0gENb3t7vAgmQSi5VfxxtgWQOr
Vl6BDVAO8AN2DnQlxWTI5wAAAABJRU5ErkJggg==}
PMCode166.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAApUlEQVR4nO2V0Q6AIAhFva3//2V6
aJaSbEKSucFT0uAe6yogojQztqnqAfAHgN1bAEDlciLCpwBcFACV6+m/IADMHuDmSulpMDcAbqSe
fH7m76GdBaVIq7EEIfbTAOTmt3BZiwtEA/HChBzcNlW7AerdS2LU+EqDALxiHYDaXJK/8KUJeX/1
HXRWLXUPtCB68sMBshjPWWaBGWBUrHMMAyAAAsArDnZffSvsfu+WAAAAAElFTkSuQmCC}
PMCode174.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAArElEQVR4nO2VUQ6AIAxDqfH+V64f
Bh0TI0MBSbY/lmx9QBkgGUbGMlTdAf4AsLYWAJC4nCS6AmhRAJTr4VfgANUe0OYK4Wqwoj41oxhA
tgoZiKdXYAaQ4rKTzFlOwgQQxc/ushZHxgLxwoQavO5XLQZId38nxn33IW/SVwCtYh4AkojHm/pf
BnqaUPc3z6C9aqo5kINI8kbxaoAIoXPd/oIvY55n6AAO4ACtYgMNTlwlYCgXiAAAAABJRU5ErkJg
gg==}
PMCode182.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAxUlEQVR4nO2V4Q7CIAyEPeP7v/L5
w1RLbRkUZzWhyRJgo/cNLi1IXirjWqq+AX4B4Ha2AIDG5SSh58snYAW8IAl57PflV7AB0ibUdylj
a7DTAADQE+uty9i+x2wv0CJe4ggizDcDIMlfwnovniAzEAsmtOC5rjoM0P59JEbnlPoRmnA0QS+O
ynAX4M2tCaARHwxfQWuuKC++aUKbf7oGPXb9VR3wIEbWPw4gYnYt0wvSABokIyxR3o43wLIHVqP8
BDZAOcAd1R+VK6856FAAAAAASUVORK5CYII=}
PMCode190.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAyklEQVR4nO2V4QrDIAyEvbH3f+Xb
j5IuBqeJ0qYDA4U21NynnhEkS2a8UtU3wBMA3lcLAKhcThL6e3kFrEArSEIe+3/6FmyAaRPqvZR3
azBXnZlWDKA5Cg2I0SkIA2hxXUnnIisRAhDxb3U9FmcmArFgQgs+d6u6AerZ/xLjMfvia1CldE6B
t0AvRgbsAozc7AmPD9xbQBKyvLX/deBOE9r64R50jPqrPtCCqPJB8WkAgbC52+4CCzIjLJF+HW+A
ZQ+sRvoKbIB0gA9sDnQlNAtkPAAAAABJRU5ErkJggg==}
PMCode210.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA80lEQVR4nO2WQQ6EMAhFy2Tuf2Vm
RYIIWD5OcCGJia0WXj9UJGZek/YZjf4C3AFARK0i+nYBrswCMjPpcUsBcX6lAjOTXPZdGICIWHbj
Od41GMBKacd/B7jL4CLUkss9ogIEoPO/Oy/39jlVe4EO4jmOICIrKSDOPcn1XAUiLcLsaFVOQeYn
BLC70LuPgunnNj0RxCkFXnWjZtd7qTsBRMWEwHgK2nfCFEQyZnJGacrSlhZhpbAqBXtYN/0dKANk
QarBYQAJZueQXgADaBC0Fa/1gHbc+iPKxtt+OinI2uyutVKg/wlRH+M10D4FXRtXYBzgB8jP4jHH
n0AAAAAAAElFTkSuQmCC}
PMCode214.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA/ElEQVR4nO2W4QrDMAiEvbH3f+Xb
L4dYtal2ZIMJhSZpL1/MpRYkZWc8ts7+B7gDAMDIRM8pwFl4QJKw7VEGVPwsCyShl3+2DQCAuppI
eDXaAD6Vvv1xgLuibUKbcr3vZKEFYPd/tV/v/Tiu1gI7SSScQaR6VwBU/J1yO2ZArkCUJqyOlh+o
llHppAB+FXb1mRrlmCWR+jtxMGHk7m7496PTcgDIzNSBiTLon0m3IEsjSWTugsQmrExZmrBysh+o
LF/q/NR3IIJY6b8dQCfzfZ1a0AawIN1SLPIF5Xj0R1S1l3UmW1CV2dUYbYH9J+xqbPfA+BRMY3sG
tgO8ALb91iuxXJigAAAAAElFTkSuQmCC}
PMCode218.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA/klEQVR4nO2W4Q7CMAiEe8b3f+Xz
jyzIKBswrSaSmEh18PWAdiA5VtptafY/wBUAAFpNdO8CHJkFJAnttxSQ4EcqkIR87H/LAAAou/EC
n7UygJXS+m8HuMrKTagll+8VFVA5igG4T8GBOJqCNIBOriPptYwSKQBJLtF1oq0MSYiwCaPRykxB
FGcKoOd880e8O5LAeKqgkkbnxG4KvO6umn3em5YdgPzoKZAF2CnoKDctgZVtJq+2WZlmyUMAuwMv
WeSfjvNT54AH8bKeTF4GEAi79rG7wIJUr+IxvuA6br0RRf7pOJ0S2HOiEqNVAv1OWI2xvAfaU9C1
5QosB3gA2vbEJXk5b60AAAAASUVORK5CYII=}
PMCode222.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABAUlEQVR4nO2W4Q7CIAyEOeP7v/L5
x5qzwwLtFE1sYmJhu34tFAaSbaddtkb/A5wBAKC0ia5VgJF5QJJQv1QBEx9VgSTs559NAwCgZdMT
nrU0gC+l998OcJalN6GW3P5nqoDMUQyg+xY6EKMuWAbQ4KqkYyuVWAKw4Kaub+rYCkS4CaPW8hNR
GpHOSwDt84ff7tkFUDavQaNz4rAEo6wjgKYAwTOa2KENbbJXgUBzGMjrmb1cAl82khhlp/MzwUMA
n0EvWORP6/zUOdCDeBpfDJ4GMAg/9rG7wINkr+LWvuA6Ln0RRf60TmUJ/DmR0SgtgX4TZjW274Fy
F1RtewW2A9wAU0S4GUF2plMAAAAASUVORK5CYII=}
PMCode246.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAA+0lEQVR4nO2W6w7DIAiFPcve/5XZ
j4WOUaAILm7JSJrUS4+feNSCiMbOuG0d/Q+wAgBAy0T3LsBVaEAigiy3MsDiV1kgIvCj+5YBABDP
xhLORhlAp1KXPw6wKsomlCnn90oWSgBy/bP1/K7bMXsXyEEsYQ/C1ZsBYPHXwPJbHCAzEKEJ462l
m/yukY4LoGfxPntPj4wsxefEyYSWu6uhv7d2ywnAM1MFxsqg7uMugZfGp4jnL5gmjEwZmjB2sm7y
u0Y6v3UOWBCZ+uUAPJiuq9wFZQAJUr2Kx/iC67j1RxSV0zqdJYiu2Wy0lkD+E1Y1tnugvQu6sT0D
2wEerP3WK33fmdQAAAAASUVORK5CYII=}
PMCode254.png
{iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAABCElEQVR4nO2W0Q7DIAhFucv+/5fZ
y+goRVRo65aMZMnQ9nJA0YKZaaU9lkb/A5wBAKC0iZ5VgJ5ZQGaG9ksVEPFeFZgZ8rPPpgEAsGTj
CY9aGsCW0vqXA5xl6U2oSy7/M1VA5igG4L4FB6LXBdMAOrhW0mMzlZgCkOAfdf0utpEZiHATxq1l
p9qPRjpNAN3nm086Tx8K71kdNDonDksQ0fYBiIhA+2VydFRihzaUSa8CgWY3kNUTay6BLRszQ8rb
zg/uJmwFDwFsBl6w2B/T+a1zwIPYjU8GTwMIhB277S6wINmrmOgLruPSF1HkD+tUlsCeExmN0hLo
b8KsxvI9UO6Cqi2vwHKAF0dEuBnX9mwjAAAAAElFTkSuQmCC}
}

foreach {name data} $icons {
        set out [open $name wb]
        puts -nonewline $out [::base64::decode $data]
        close $out
    }
