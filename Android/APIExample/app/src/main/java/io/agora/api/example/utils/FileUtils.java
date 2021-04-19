package io.agora.api.example.utils;

import java.io.Closeable;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;

public final class FileUtils {

  public static boolean writeFileFromBytesByChannel(final String filePath,
                                                    final byte[] bytes,
                                                    final boolean append,
                                                    final boolean isForce) {
    return writeFileFromBytesByChannel(getFileByPath(filePath), bytes, append,
                                       isForce);
  }

  public static boolean writeFileFromBytesByChannel(final File file,
                                                    final byte[] bytes,
                                                    final boolean append,
                                                    final boolean isForce) {
    if (bytes == null)
      return false;
    FileChannel fc = null;
    try {
      fc = new FileOutputStream(file, append).getChannel();
      fc.position(fc.size());
      fc.write(ByteBuffer.wrap(bytes));
      if (isForce)
        fc.force(true);
      return true;
    } catch (IOException e) {
      e.printStackTrace();
      return false;
    } finally {
      closeIO(fc);
    }
  }

  public static void closeIO(final Closeable... closeables) {
    if (closeables == null)
      return;
    for (Closeable closeable : closeables) {
      if (closeable != null) {
        try {
          closeable.close();
        } catch (IOException e) {
          e.printStackTrace();
        }
      }
    }
  }

  private static File getFileByPath(final String filePath) {
    return isSpace(filePath) ? null : new File(filePath);
  }

  private static boolean createOrExistsDir(final File file) {
    return file != null && (file.exists() ? file.isDirectory() : file.mkdirs());
  }

  private static boolean isSpace(final String s) {
    if (s == null)
      return true;
    for (int i = 0, len = s.length(); i < len; ++i) {
      if (!Character.isWhitespace(s.charAt(i))) {
        return false;
      }
    }
    return true;
  }
}