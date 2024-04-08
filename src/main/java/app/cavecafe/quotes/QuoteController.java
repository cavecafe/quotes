package app.cavecafe.quotes;

import jakarta.annotation.PostConstruct;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Random;

@RestController
public class QuoteController {
   private static List<Quote> quoteCache;

   @PostConstruct
   private void init() throws IOException {
      List<Quote> quotes = Util.loadQuotes();
      quoteCache = Collections.unmodifiableList(quotes);
   }

   @GetMapping("/quote")
   public Quote getRandomQuote(@RequestParam(value = "lang", defaultValue = "en") String language) {
      Random random = new Random();
      int randomIndex = random.nextInt(quoteCache.size());
      return quoteCache.get(randomIndex);
   }
}
