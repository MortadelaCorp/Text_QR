package es.upv.epsa.ti.ttqr;

import android.graphics.Bitmap;
import android.graphics.Color;

public class TextCleaner_threads {
	
	private Bitmap edgeImg;
	private Bitmap highContrastGreyImage;
	private int width;
	private int height;
	
	public Bitmap generateEdgeImage(Bitmap highContrastGreyImage, int width, int height) {

		edgeImg = Bitmap.createBitmap(width, height, highContrastGreyImage.getConfig());
		this.highContrastGreyImage = highContrastGreyImage;
		this.width = width;
		this.height = height;
		
		int numThreads = 1;
				
		for(int i = 0; i < numThreads - 1; i++){
			new ThreadProcess(height/numThreads * i, height/numThreads * (i+1) - 1).start();
		}
			ThreadProcess t = new ThreadProcess(height/numThreads * (numThreads - 1), height);
			t.start();
		try {
			t.join();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

		return edgeImg;		
	}
	
	private void edgeFunction(int y0, int y1) {
		
		int x = 0, y = 0;
		int left = 0, upper = 0, rightUpper = 0;

		for(y = y0; y < y1; y++) {
			for(x = 0; x < width; x++) {
				
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
		
	}
	
	/**
	 * External thread used to do more time consuming image processing
	 */
	private class ThreadProcess extends Thread {
		
		private int y0, y1;
		
		ThreadProcess(int y0, int y1) {
			this.y0 = y0;
			this.y1 = y1;
		}
		
		@Override
		public void run() {
			edgeFunction(y0, y1);
		}
	}
	
}
