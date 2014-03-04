package es.upv.epsa.ti.ttqr;

import android.graphics.Bitmap;
import android.graphics.Color;

public class TextCleaner {

	public Bitmap generateEdgeImage(Bitmap highContrastGreyImage, int width, int height) {
		
		Bitmap edgeImg = Bitmap.createBitmap(width, height, highContrastGreyImage.getConfig());
		
		int x = 0, y = 0;
		int left = 0, upper = 0, rightUpper = 0;
		
		for(x = 0; x < width; x++) {
			for(y = 0; y < height; y++) {
				
				if(0 < x && x < width-1 && 0 < y && y < height) {

					int pixel = Color.blue(highContrastGreyImage.getPixel(x, y));
					int pixelLeft = Color.blue(highContrastGreyImage.getPixel(x - 1, y));
					left = pixel - pixelLeft;
					
					int pixelUp = Color.blue(highContrastGreyImage.getPixel(x, y - 1));
					upper = pixel - pixelUp;
					
					int pixelRU = Color.blue(highContrastGreyImage.getPixel(x + 1, y - 1));
					rightUpper = pixel - pixelRU;
					
					int pixelMax = Math.max(left, Math.max(upper, rightUpper));
					
					if(pixelMax < 50) { 
						edgeImg.setPixel(x, y, Color.rgb(0, 0, 0));
					} else {
						edgeImg.setPixel(x, y, Color.rgb(pixelMax, pixelMax, pixelMax));
					}

				}

			}
		}

		return edgeImg;
		
	}
	
	
}
