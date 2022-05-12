
package com.mlkit;

import android.graphics.Rect;
import androidx.annotation.NonNull;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionPoint;
import com.google.firebase.ml.vision.face.FirebaseVisionFace;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceContour;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceDetector;
import com.google.firebase.ml.vision.face.FirebaseVisionFaceDetectorOptions;
import com.google.firebase.ml.vision.text.FirebaseVisionCloudTextRecognizerOptions;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.text.FirebaseVisionText;
import com.google.firebase.ml.vision.text.FirebaseVisionTextRecognizer;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcode;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcodeDetector;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcodeDetectorOptions;

import java.io.IOException;
import java.util.List;
import java.util.ArrayList;

public class RNMlKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private FirebaseVisionTextRecognizer textDetector;
  private FirebaseVisionTextRecognizer cloudTextDetector;
  private FirebaseVisionFaceDetector faceDetector;

  public RNMlKitModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }


  @ReactMethod
  public void deviceTextRecognition(String uri, final Promise promise) {
      try {
          FirebaseVisionImage image = FirebaseVisionImage.fromFilePath(this.reactContext, android.net.Uri.parse(uri));
          FirebaseVisionTextRecognizer detector = this.getTextRecognizerInstance();
          Task<FirebaseVisionText> result =
                  detector.processImage(image)
                          .addOnSuccessListener(new OnSuccessListener<FirebaseVisionText>() {
                              @Override
                              public void onSuccess(FirebaseVisionText firebaseVisionText) {
                                  promise.resolve(processDeviceResult(firebaseVisionText));
                              }
                          })
                          .addOnFailureListener(
                                  new OnFailureListener() {
                                      @Override
                                      public void onFailure(@NonNull Exception e) {
                                          e.printStackTrace();
                                          promise.reject(e);
                                      }
                                  });;
      } catch (IOException e) {
          promise.reject(e);
          e.printStackTrace();
      }
  }
  private FirebaseVisionTextRecognizer getTextRecognizerInstance() {
    if (this.textDetector == null) {
      this.textDetector = FirebaseVision.getInstance().getOnDeviceTextRecognizer();
    }

    return this.textDetector;
  }

  @ReactMethod
  public void close(final Promise promise) {
    if(this.textDetector != null) {
      try {
        this.textDetector.close();
        this.textDetector = null;
        promise.resolve(true);
      } catch (IOException e) {
        e.printStackTrace();
        promise.reject(e);
      }
    }
  }

  /**
   * Converts firebaseVisionText into a map
   *
   * @param firebaseVisionText
   * @return
   */
  private WritableArray processDeviceResult(FirebaseVisionText firebaseVisionText) {
    //WritableArray data = Arguments.createArray();
//   WritableMap info = Arguments.createMap();
//   WritableMap coordinates = Arguments.createMap();
    List<FirebaseVisionText.TextBlock> blocks = firebaseVisionText.getTextBlocks();
    WritableArray data = serializeEventData(blocks);
    if (blocks.size() == 0) {
        return data;
    }
    
    
    //   for (int i = 0; i < blocks.size(); i++) {
    //       List<FirebaseVisionText.Line> lines = blocks.get(i).getLines();
    //       info = Arguments.createMap();
    //       coordinates = Arguments.createMap();

    //       Rect boundingBox = blocks.get(i).getBoundingBox();

    //       coordinates.putInt("top", boundingBox.top);
    //       coordinates.putInt("left", boundingBox.left);
    //       coordinates.putInt("width", boundingBox.width());
    //       coordinates.putInt("height", boundingBox.height());

    //       info.putMap("blockCoordinates", coordinates);
    //       info.putString("blockText", blocks.get(i).getText());
    //       info.putString("resultText", firebaseVisionText.getText());

    //       for (int j = 0; j < lines.size(); j++) {
    //           List<FirebaseVisionText.Element> elements = lines.get(j).getElements();
    //           info.putString("lineText", lines.get(j).getText());

    //           for (int k = 0; k < elements.size(); k++) {
    //               info.putString("elementText", elements.get(k).getText());
    //           }
    //       }

    //       data.pushMap(info);
    //   }

      return data;
  }
  private WritableArray serializeEventData(List<FirebaseVisionText.TextBlock> textBlocks) {
    WritableArray textBlocksList = Arguments.createArray();
    for (FirebaseVisionText.TextBlock block: textBlocks) {
      WritableMap serializedTextBlock = serializeBloc(block);
      textBlocksList.pushMap(serializedTextBlock);
    }

    return textBlocksList;
  }
  private WritableMap serializeBloc(FirebaseVisionText.TextBlock block) {
    WritableMap encodedText = Arguments.createMap();
    WritableArray lines = Arguments.createArray();
    for (FirebaseVisionText.Line line : block.getLines()) {
      lines.pushMap(serializeLine(line));
    }
    encodedText.putArray("components", lines);

    encodedText.putString("value", block.getText());

    WritableMap bounds = processBounds(block.getBoundingBox());

    encodedText.putMap("bounds", bounds);

    encodedText.putString("type", "block");
    return encodedText;
  }

  private WritableMap serializeLine(FirebaseVisionText.Line line) {
    WritableMap encodedText = Arguments.createMap();
    WritableArray lines = Arguments.createArray();
    for (FirebaseVisionText.Element element : line.getElements()) {
      lines.pushMap(serializeElement(element));
    }
    encodedText.putArray("components", lines);

    encodedText.putString("value", line.getText());

    WritableMap bounds = processBounds(line.getBoundingBox());

    encodedText.putMap("bounds", bounds);

    encodedText.putString("type", "line");
    return encodedText;
  }

  private WritableMap serializeElement(FirebaseVisionText.Element element) {
    WritableMap encodedText = Arguments.createMap();

    encodedText.putString("value", element.getText());

    WritableMap bounds = processBounds(element.getBoundingBox());

    encodedText.putMap("bounds", bounds);

    encodedText.putString("type", "element");
    return encodedText;
  }

  private WritableMap processBounds(Rect frame) {
    WritableMap origin = Arguments.createMap();
    int x = frame.left;
    int y = frame.top;

    // if (frame.left < mWidth / 2) {
    //   x = x + mPaddingLeft / 2;
    // } else if (frame.left > mWidth /2) {
    //   x = x - mPaddingLeft / 2;
    // }

    // if (frame.top < mHeight / 2) {
    //   y = y + mPaddingTop / 2;
    // } else if (frame.top > mHeight / 2) {
    //   y = y - mPaddingTop / 2;
    // }

    origin.putDouble("x", x);
    origin.putDouble("y", y);

    WritableMap size = Arguments.createMap();
    size.putDouble("width", frame.width());
    size.putDouble("height", frame.height());

    WritableMap bounds = Arguments.createMap();
    bounds.putMap("origin", origin);
    bounds.putMap("size", size);
    return bounds;
  }

  @Override
  public String getName() {
    return "RNMlKit";
  }
}
