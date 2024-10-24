import java.time.LocalTime;

/**
 * Run this java file via `java --source 11 local_time_to_nano_of_day.java [local_time_string]`.
 *
 * Note: this script is designed for use from:
 * elasticgraph-support/spec/unit/elastic_graph/support/time_util_spec.rb
 */
public class LocalTimeToNanoOfDay {
  public static void main(String[] args) {
    LocalTime time = LocalTime.parse(args[0]);
    System.out.println(time.toNanoOfDay());
  }
}
