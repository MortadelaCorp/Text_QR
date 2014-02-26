package es.upv.epsa.ti.ttqr;

import java.util.ArrayList;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Rect;
import android.util.Log;

public class TextRegionDetector {

	private Bitmap edgeImg;
	
	public TextRegionDetector(Bitmap bmp) {
		
		this.edgeImg = bmp;
		
	}
	
	public ArrayList<Rect> textRegion() {
		
		int left = 0, right = 0, top = 0, bottom = 0;

		ArrayList<Rect> textArea = determineYCoordinate(lineHistogram(50));

		return textArea;
	}
	
	private ArrayList<Rect> determineYCoordinate(int[] lineHistogram) {

		int y0 = 0, y1 = 0;
		int line = 0;
		ArrayList<Rect> TC = new ArrayList<Rect>();

		boolean insideTextArea = false;
	
		while(line < lineHistogram.length) {
			
			if(lineHistogram[line] == 1 && !insideTextArea) {
								
				y0 = line;
				insideTextArea = true;
				
			} else if(lineHistogram[line] == 0 && insideTextArea) {
				
				y1 = line - 1;
				insideTextArea = false;
				
			}
			
			if(y0 > 0 && y1 > 0 && y1-y0 > 20) {
										// left top right bottom
				Rect textRegion = new Rect(0, y0, edgeImg.getWidth(), y1);
				TC.add(textRegion);
				
				y0 = 0;
				y1 = 0;
				
			}

			line++;

		}

		return TC;
	}
	
	private int[] lineHistogram(int value) {
		
		
		int x, y, num;
		int width = edgeImg.getWidth();
		int height = edgeImg.getHeight();
		
		int[] histograma = new int[height];
		
		for(int i = 0; i < height; i++){
			histograma[i] = 0;
		}

		for(y = 0; y < height; y++) {
			
			num = 0;
			
			for(x = 0; x < width; x++) {

				if(Color.red(edgeImg.getPixel(x, y)) >= value) {
					num++;
				}

			}
			
			if(num > 10) {
				histograma[y] = 1;
			}
			
		}
		
		
		return histograma;
		
	}
	
	
}
