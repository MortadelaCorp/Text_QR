package es.upv.epsa.ti.ttqr;

import android.graphics.Bitmap;
import android.graphics.Color;

public class TextCleaner {
	
	private Bitmap highContrastGreyImage;
	private int width;
	private int height;

	public TextCleaner(Bitmap bmp) {
		this.highContrastGreyImage = bmp;
		
		this.width = highContrastGreyImage.getWidth();
		this.height = highContrastGreyImage.getHeight();
		
	}
	
	public Bitmap generateEdgeImage() {
		
		Bitmap edgeImg = Bitmap.createBitmap(width, height, highContrastGreyImage.getConfig());
		
		int x = 0, y = 0;
		int left = 0, upper = 0, rightUpper = 0;
		
		for(x = 0; x < width; x++) {
			for(y = 0; y < height; y++) {
				
				if(0 < x && x < width-1 && 0 < y && y < height) {
					
					int pixel = Math.abs(highContrastGreyImage.getPixel(x, y));
					int pixelLeft = Math.abs(highContrastGreyImage.getPixel(x - 1, y));
					left = pixel - pixelLeft;
					
					int pixelUp = Math.abs(highContrastGreyImage.getPixel(x, y - 1));
					upper = pixel - pixelUp;
					
					int pixelRU = Math.abs(highContrastGreyImage.getPixel(x + 1, y - 1));
					rightUpper = pixel - pixelRU;
					
					int pixelMax = Math.max(left, Math.max(upper, rightUpper));
					
					edgeImg.setPixel(x, y, pixelMax);

				} else {
					
					edgeImg.setPixel(x, y, 0);
					
				}

				
			}
		}
		
		
		
		
		
		return edgeImg;
		
	}
	
	
}
