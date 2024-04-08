package app.cavecafe.quotes;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;


public class Util {
   public static List<Quote> loadQuotes() throws IOException {
      ObjectMapper mapper = new ObjectMapper();
      InputStream inputStream = Util.class.getClassLoader().getResourceAsStream("quotes.json");
      return mapper.readerForListOf(Quote.class).readValue(inputStream);
   }
}
