package com.github.axet.lookup.common;

import java.awt.image.BufferedImage;

public abstract class ImageBinaryScale {

    // original image
    public ImageBinary image;
    // scaled buffered image
    public BufferedImage scaleBuf;
    // scaled binary
    public ImageBinary scaleBin;

    // scale 0.5f for 50%
    public double s = 0;
    // blur kernel size
    public int k = 0;

    public void rescale(int s, int k) {
        rescale(project(s), k);
    }

    public double project(int s) {
        double m = (double) Math.min(image.getWidth(), image.getHeight());
        double q = m / s;

        q = Math.ceil(q);

        q = 1 / q;

        return q;
    }

    public void rescale(double s, int k) {
        this.s = s;
        this.k = k;

        rescale();
    }

    abstract public void rescale();

    /**
     * default image width for scale image is scale image width
     * 
     * @return
     */
    public int getWidth() {
        return scaleBuf.getWidth();
    }

    /**
     * default image height for scale image is scale image height
     * 
     * @return
     */
    public int getHeight() {
        return scaleBuf.getHeight();
    }
}
