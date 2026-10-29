if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  # Software cursor: a workaround for the NVIDIA driver, so only where it is loaded.
  # On Intel-only machines (think-arch-think) it just costs a redraw per mouse move.
  [[ -e /proc/driver/nvidia ]] && export WLR_NO_HARDWARE_CURSORS=1
  
  #export WLR_DRM_DEVICES=/dev/dri/card0
  
  #export WLR_RENDERER=vulkan
  
  exec ~/.local/bin/start-wayfire 
fi
