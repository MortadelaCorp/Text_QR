package com.github.axet.lookup.common;

import java.awt.image.BufferedImage;

import com.github.axet.lookup.Lookup;

public class ImageBinaryGreyScale extends ImageBinaryScale {

    public ImageBinaryGreyScale(BufferedImage i) {
        image = new ImageBinaryGrey(i);
        s = 1f;
        k = 0;
        scaleBuf = i;
        scaleBin = image;
    }

    /**
     * 
     * @param i
     * @param scaleSize
     *            template scale size in pixels you wish. (ex: 5)
     */
    public ImageBinaryGreyScale(BufferedImage i, int scaleSize, int blurKernel) {
        image = new ImageBinaryGrey(i);

        rescale(scaleSize, blurKernel);
    }

    public ImageBinaryGreyScale(BufferedImage i, double scale, int blurKernel) {
        image = new ImageBinaryGrey(i);
        k = blurKernel;

        s = scale;

        rescale();
    }

    public void rescale() {
        scaleBuf = Lookup.scale(image.getImage(), s, k);
        scaleBin = new ImageBinaryGrey(scaleBuf);
    }
}
