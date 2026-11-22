"""Original vector art and synthesized sound; no stock or network assets."""
from pathlib import Path
import math, wave, struct, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
ROOT = Path(__file__).resolve().parents[1]
audio = ROOT/'assets/audio'; audio.mkdir(parents=True, exist_ok=True)
RATE=22050

def wav(name, seconds, synth):
    samples=[]
    for i in range(int(seconds*RATE)):
        t=i/RATE
        samples.append(struct.pack('<h',int(max(-1,min(1,synth(t)))*23000)))
    with wave.open(str(audio/(name+'.wav')),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed')); f.writeframes(b''.join(samples))

def tone(t, f): return math.sin(2*math.pi*f*t)
wav('place',.14,lambda t:(tone(t,660)+.4*tone(t,1320))*.45*math.exp(-30*t))
wav('click',.07,lambda t:tone(t,880)*.3*math.exp(-60*t))
wav('clear',.5,lambda t:sum(tone(t,f) for f in [523.25,659.25,783.99])*math.exp(-8*t)*.22)
wav('combo',.7,lambda t:sum(tone(t,f) for f in [523.25,659.25,783.99,1046.5])*math.exp(-5*t)*.18)
wav('end',.8,lambda t:(tone(t,220)+tone(t,261.63))*math.exp(-5*t)*.25)
notes=[130.81,164.81,196,261.63,110,130.81,164.81,220,87.31,130.81,174.61,220,98,146.83,196,246.94]
def music(t):
    step=int(t/.5); phase=t%.5; f=notes[step%len(notes)]
    beat=math.sin(2*math.pi*(50*phase+1.5*(1-math.exp(-35*phase))))*math.exp(-22*phase)*.3
    arp=(tone(t,f*2)+tone(t,f*4)*.25)*math.exp(-5*phase)*.13
    return (beat+arp)*min(1,t*5,(8-t)*5)
wav('pulse',8,music)
# Explicit loop import settings.
(audio/'pulse.wav.import').write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[deps]\nsource_file="res://assets/audio/pulse.wav"\n\n[params]\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n')
svg='''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><rect width="512" height="512" rx="112" fill="#080d20"/><rect x="32" y="32" width="448" height="448" rx="90" fill="none" stroke="#233759" stroke-width="3"/><g stroke-width="5"><g fill="#126c8a" stroke="#49edec"><rect x="115" y="115" width="84" height="84" rx="18"/><rect x="214" y="115" width="84" height="84" rx="18"/><rect x="115" y="214" width="84" height="84" rx="18"/></g><g fill="#7945b0" stroke="#c59bff"><rect x="214" y="214" width="84" height="84" rx="18"/><rect x="313" y="214" width="84" height="84" rx="18"/><rect x="313" y="313" width="84" height="84" rx="18"/></g></g></svg>'''
(ROOT/'assets/icon.svg').write_text(svg)
def icon():
    im=Image.new('RGB',(512,512),'#080d20'); d=ImageDraw.Draw(im)
    d.rounded_rectangle((24,24,488,488),92,outline='#233759',width=3)
    for x,y,c in [(115,115,'#49edec'),(214,115,'#49edec'),(115,214,'#49edec'),(214,214,'#b98cff'),(313,214,'#b98cff'),(313,313,'#b98cff')]:
        d.rounded_rectangle((x,y,x+84,y+84),18,fill=c)
        d.rounded_rectangle((x+6,y+6,x+78,y+78),13,fill='#15374e' if x<214 else '#513571')
    return im
icon().save(ROOT/'store/icon-512.png')
im=Image.new('RGB',(1024,500),'#080d20'); d=ImageDraw.Draw(im)
font='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
f=ImageFont.truetype(font,66); s=ImageFont.truetype(font,22)
im.paste(icon().resize((380,380)),(605,60))
d.text((58,110),'NEON',font=f,fill='#49edec'); d.text((58,186),'BLOCK MASTER',font=ImageFont.truetype(font,48),fill='#f2f3ff')
d.text((61,287),'FIND YOUR FLOW.',font=s,fill='#b3a4f4'); d.text((61,328),'8 × 8   /   CLASSIC · TIME · DAILY',font=ImageFont.truetype(font,18),fill='#8291b4')
im.save(ROOT/'store/feature-1024x500.png')

# Bake atmospheric gradients once instead of overdraw on mobile GPUs.
im=Image.new('RGB',(720,1280)); pix=im.load()
for y in range(1280):
    for x in range(720):
        a=math.exp(-((x-620)**2+(y-200)**2)/(2*290**2))
        b=math.exp(-((x+70)**2+(y-950)**2)/(2*280**2))
        grid=2 if x%40==0 or y%40==0 else 0
        pix[x,y]=(int(8+8*b+2*a)+grid,int(13+6*a+2*b)+grid,int(30+17*a+12*b)+grid)
im.save(ROOT/'assets/backdrop.png')
