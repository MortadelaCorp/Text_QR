package es.upv.epsa.ti.ttqr;

import android.graphics.Bitmap;
import android.graphics.Rect;

public class TextRegionDetector {

	private Bitmap edgeImg;
	
	public TextRegionDetector(Bitmap bmp) {
		
		this.edgeImg = bmp;
		
	}
	
	public Rect textRegion() {
		
		int left = 0, right = 0, top = 0, bottom = 0;

		determineYCoordinate(lineHistogram(), 100);
		
		
		
		Rect textArea = new Rect(left, right, top, bottom);
		
		return textArea;
	}
	
	private Rect[] determineYCoordinate(int[][] lineHistogram, int value) {
		
		Rect textRegion;
		Rect[] TC; //text coordinates
		int num;

		int y = 1, j = 0;
		boolean insideTextArea = false;

		for(int i = 0; i < edgeImg.getHeight(); i++) {		
			for(int t = 0; t < 256; t++) {
				if(lineHistogram[t][i] >= value) {
					num = lineHistogram[t][i];
				}
			}
		}
		
		
		
		
		return TC;
	}
	
	private int[][] lineHistogram() {
		
		
		int x, y;
		int width = edgeImg.getWidth();
		int height = edgeImg.getHeight();
		
		int[][] histograma = new int[256][height];
		
		for(int i = 0; i < edgeImg.getHeight(); i++) {
			for(int j = 0; j < 256; j++){
				histograma[i][j] = 0;
			}
		}


		for(y = 0; y < height; y++) {
			for(x = 0; x < width; x++) {

				histograma[edgeImg.getPixel(x, y)][y] += 1;

			}
		}
		
		
		return histograma;
	}
	
	
}
