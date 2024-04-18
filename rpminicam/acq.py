""" Minicam video acquisition.
rpminicam/acq.py

Written by DMM, Oct 2023
"""

import os
import picamera
import gpiozero
import time
import numpy as np


def list_subdirs(rootdir, givepath=False):
    paths = []
    names = []
    for item in os.scandir(rootdir):
        if os.path.isdir(item):
            if item.name[0]!='.':
                paths.append(item.path)
                names.append(item.name)

    if givepath:
        return paths
    elif not givepath:
        return names


def do_rec():

    # read input trigger
    trig = gpiozero.Button(23)

    # start/stop button
    button = gpiozero.Button(22)

    # led indicator
    led = gpiozero.LED(15)

    datapath = '/home/rpi/Data/rpminicam_recordings/'

    vids = list_subdirs(datapath)
    
    vids_inds = []
    for v in vids:
        vi = os.path.splitext(v)[0].split('_')[1]
        vids_inds.append(int(vi))
    if len(vids_inds) > 0:
        curind = np.max(vids_inds) + 1
    else:
        curind = 0


    newdatapath = os.path.join(datapath, 'vid_{}'.format(str(curind).zfill(2)))
    os.mkdir(newdatapath)
    datapath = newdatapath
    print('folder created ')

    # wait for button press, then it will listen for a trigger from the TTL
    print('waiting for button press')
    button.wait_for_press()
    print('start/stop button pressed')
    
    with picamera.PiCamera(framerate=60, resolution=(640,480)) as cam:
        

        led.on()
        trig.wait_for_press()
        # print('trig pressed ')
        led.off()

        cam.start_recording(
            output=os.path.join(datapath,
                                'vid_{}.h264'.format(str(curind).zfill(3))),
            format='h264')
        
        button.wait_for_press()
    
        print('recording stoped')
        cam.stop_recording()
        
        print('done')
        return



def main():

    do_rec()
    
    # At the end of the recording, reset and start a new recording
    # upon a button press.
    button = gpiozero.Button(0)
    led = gpiozero.LED(1)
    led.on()
    button.wait_for_press()
    led.off()

    main()



if __name__ == '__main__':

    main()
