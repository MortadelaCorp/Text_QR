package es.upv.epsa.ti.textimagedetector;

import java.util.ArrayList;
import java.util.List;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Rect;

public class TextRegionDetector {
	private static int TOLERANCE_VALUE = 100;
	private static int Y_HISTOGRAM_TOLERANCE_VALUE = 2;
	private static int X_HISTOGRAM_TOLERANCE_VALUE = 0;
	
	public List<Rect> textRegion(Bitmap edgeImg) {
		return determineXCoordinate(
				determineYCoordinate(edgeImg, lineHistogramY(edgeImg, TOLERANCE_VALUE)), 
				edgeImg);		
	}
	
	private List<Rect> determineYCoordinate(Bitmap edgeImg, int[] lineHistogram) {
		int y0 = 0, y1 = 0;
		List<Rect> textAreas = new ArrayList<Rect>();	
		int minHeightSize = edgeImg.getHeight() * 10 / 100;
		int maxHeightSize = edgeImg.getHeight() * 90 / 100;
		boolean insideTextArea = false;
	
		for(int i = 0; i < lineHistogram.length; i++) {			
			if(lineHistogram[i] == 1 && !insideTextArea) {			
				if(i-3 >= 0) {
					y0 = i-3;
				} else {
					y0 = i;
				}
				insideTextArea = true;				
			} else if(lineHistogram[i] == 0 && insideTextArea) {				
				if(i+3 < edgeImg.getHeight()) {
					y1 = i+3;
				} else {
					y1 = i;
				}
				insideTextArea = false;				
			} else if(lineHistogram[i] == 1 && insideTextArea) {
				if(i == lineHistogram.length - 1) y1 = i;
			}
			
			if(y0 > 0 && y1 > 0 && (y1-y0) > minHeightSize && (y1-y0) < maxHeightSize) {
									  // left top        right      bottom
				Rect textRegion = new Rect(0, y0, edgeImg.getWidth(), y1);
				textAreas.add(textRegion);
				
				y0 = 0;
				y1 = 0;			
			}
		}
		
		return textAreas;
	}	

	private int[] lineHistogramY(Bitmap edgeImg, int value) {
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
			
			if(num > Y_HISTOGRAM_TOLERANCE_VALUE) {
				histograma[y] = 1;
			}		
		}

		return histograma;		
	}
	
	private List<Rect> determineXCoordinate(List<Rect> lineas, Bitmap edgeImg) {
		int x0 = 0, x1 = 0, num1 = 0, num0 = 0, total = 0;
		int l;
		List<Rect> returnAreas = new ArrayList<Rect>();
		
		for(int i = 0; i < lineas.size(); i++) {
			int[] lineHistogram = lineHistogramX(lineas.get(i), edgeImg, TOLERANCE_VALUE);
			
			x0 = 0;
			x1 = 0;
			num1 = 0;
			num0 = 0;
			total = 0;
			
			for(int n : lineHistogram) {
				if(n == 1) {
					total++;
				}
			}
			
			final int totalMinLimit = lineHistogram.length * 10 / 100;
			final int totalMaxLimit = lineHistogram.length * 95 / 100;
			
			if(total < totalMaxLimit) {				
				for(l = 0; l < lineHistogram.length; l++) {
					if(lineHistogram[l] == 1) {
						num1++;
						if(num1 > totalMinLimit) {
							if(l - totalMinLimit - 2 > lineas.get(i).left){
								x0 = l - totalMinLimit - 2;
							}
							else {
								x0 = lineas.get(i).left;
							}
							num1 = 0;
							num0 = 0;
							break;
						}
					} else {
						num0++;
						if(num0 > totalMinLimit) {
							num1 = 0;
							num0 = 0;
						}
					}			
				}
				
				for(l = lineHistogram.length - 1; l > 0; l--) {
					if(lineHistogram[l] == 1) {
						num1++;
						if(num1 > totalMinLimit) {
							if(l + totalMinLimit + 2 < lineas.get(i).right){
								x1 = l + totalMinLimit + 2;
							}
							else {
								x1 = lineas.get(i).right;
							}
							num1 = 0;
							num0 = 0;
							break;
						}
					} else {
						num0++;
						if(num0 > totalMinLimit) {
							num1 = 0;
							num0 = 0;
						}
					}		
				}				
										// left     top         right       bottom
				Rect textRegion = new Rect(x0, lineas.get(i).top, x1, lineas.get(i).bottom);
				returnAreas.add(textRegion);			
			}		
		}
		
		return returnAreas;
	}
	
	private int[] lineHistogramX(Rect linea, Bitmap edgeImg, int value) {		
		int x, y, num;
		int width = linea.width();		
		int[] histograma = new int[width];
		
		for(int i = 0; i < width; i++){
			histograma[i] = 0;
		}

		for(x = 0; x < width; x++) {			
			num = 0;		
			for(y = linea.top; y < linea.bottom; y++) {
				if(Color.red(edgeImg.getPixel(x, y)) >= value) {
					num++;
				}
			}			
			if(num > X_HISTOGRAM_TOLERANCE_VALUE) {
				histograma[x] = 1;
			}			
		}
	
		return histograma;		
	}

}
