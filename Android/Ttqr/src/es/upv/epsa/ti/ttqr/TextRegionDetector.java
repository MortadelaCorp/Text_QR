package es.upv.epsa.ti.ttqr;

import java.util.ArrayList;

import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Rect;
import android.util.Log;

public class TextRegionDetector {

	private Bitmap edgeImg;
	private ArrayList<Rect> textAreas = new ArrayList<Rect>();
	private ArrayList<Rect> returnAreas = new ArrayList<Rect>();
	
	public TextRegionDetector() {

	}

	public void setEdgeImg(Bitmap edgeImg) {
		this.edgeImg = edgeImg;
	}

	public TextRegionDetector(Bitmap bmp) {
		
		this.edgeImg = bmp;
		
	}
	
	public ArrayList<Rect> textRegion() {
		
		textAreas.clear();
		returnAreas.clear();
		determineYCoordinate(lineHistogramY(50));
		determineXCoordinate(textAreas);

		return returnAreas;
	}
	
	private void determineXCoordinate(ArrayList<Rect> lineas) {

		int x0 = 0, x1 = 0, num1 = 0, num0 = 0, total = 0;
		int l;
		
		for(int i = 0; i < lineas.size(); i++) {

			int[] lineHistogram = lineHistogramX(lineas.get(i), 50);

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
			if(total > 50 && total < 150) {
				
				for(l = 0; l < lineHistogram.length; l++) {
					if(lineHistogram[l] == 1) {
						num1++;
						if(num1 > 10) {
							x0 = l - 10;
							num1 = 0;
							num0 = 0;
							break;
						}
					} else {
						num0++;
						if(num0 > 10) {
							num1 = 0;
							num0 = 0;
						}
					}			
				}
				
				for(l = lineHistogram.length - 1; l > 0; l--) {
					if(lineHistogram[l] == 1) {
						num1++;
						if(num1 > 10) {
							x1 = l + 10;
							num1 = 0;
							num0 = 0;
							break;
						}
					} else {
						num0++;
						if(num0 > 10) {
							num1 = 0;
							num0 = 0;
						}
					}		
				}
				
											// left top right bottom
				Rect textRegion = new Rect(x0, lineas.get(i).top, x1, lineas.get(i).bottom);
				returnAreas.add(textRegion);
				
			}
			
		}

	}
	
	/*private void determineXCoordinate(ArrayList<Rect> lineas) {

		int x0 = 0, x1 = 0;

		boolean insideTextArea = false;
		
		for(int i = 0; i < lineas.size(); i++) {

			int[] lineHistogram = lineHistogramX(lineas.get(i), 50);
			
			for(int j = 0; j < lineHistogram.length; j++) {
				
				if(lineHistogram[j] == 1 && !insideTextArea) {
									
					x0 = j;
					insideTextArea = true;
					
				} else if(lineHistogram[j] == 0 && insideTextArea) {
					
					x1 = j - 1;
					insideTextArea = false;
					
				}
				
				if(x0 > 0 && x1 > 0 && x1-x0 > 15) {
											// left top right bottom
					Rect textRegion = new Rect(x0, lineas.get(i).top, x1, lineas.get(i).bottom);
					textAreas.add(textRegion);
					
					x0 = 0;
					x1 = 0;
					
				}

			}
		}

	}*/
	
	private void determineYCoordinate(int[] lineHistogram) {

		int y0 = 0, y1 = 0;

		boolean insideTextArea = false;
	
		for(int i = 0; i < lineHistogram.length; i++) {
			
			if(lineHistogram[i] == 1 && !insideTextArea) {
				
				if(i-5 >= 0) {
					y0 = i-5;
				} else {
					y0 = i;
				}

				insideTextArea = true;
				
			} else if(lineHistogram[i] == 0 && insideTextArea) {
				
				if(i+5 < edgeImg.getHeight()) {
					y1 = i+5;
				} else {
					y1 = i;
				}
				insideTextArea = false;
				
			} else if(lineHistogram[i] == 1 && insideTextArea) {
				if(i == lineHistogram.length - 1) y1 = i;
			}
			
			if(y0 > 0 && y1 > 0 && y1-y0 > 18) {
										// left top right bottom
				Rect textRegion = new Rect(0, y0, edgeImg.getWidth(), y1);
				textAreas.add(textRegion);
				
				y0 = 0;
				y1 = 0;
				
			}

		}

	}
	
private int[] lineHistogramX(Rect linea, int value) {
		
		
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
			
			if(num > 0) {
				histograma[x] = 1;
			}
			
		}
		
		
		return histograma;
		
	}

	private int[] lineHistogramY(int value) {
		
		
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
			
			if(num > 20) {
				histograma[y] = 1;
			}
			
		}
		
		
		return histograma;
		
	}
}
