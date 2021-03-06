require 'wordnet_based_similarity'
require 'constants'

class PredictClass
=begin
 Identifies the probabilities of a review belonging to each of the three classes. 
 Returns an array of probablities (length = numClasses) 
=end
#predicting the review's class
def predict_classes(pos_tagger, _core_NLP_tagger, _review_text, review_graph, pattern_files_array, num_classes)
  #reading the patterns from the pattern files
  patterns_files = Array.new
  pattern_files_array.each do |file|
    patterns_files << file #collecting the file names for each class of patterns
  end
  
  tc = TextPreprocessing.new
  single_patterns = Array.new(num_classes){Array.new}
  #reading the patterns from each of the pattern files
  for i in (0..num_classes - 1) #for every class
    #read_patterns in TextPreprocessing helps read patterns in the format 'X = Y'
    single_patterns[i] = tc.read_patterns(patterns_files[i], pos_tagger) 
  end
  
  #Predicting the probability of the review belonging to each of the content classes
  wordnet = WordnetBasedSimilarity.new
  edges = review_graph.edges
#  puts "review_graph.num_edges #{review_graph.num_edges}"
  
  class_prob = Array.new #contains the probabilities for each of the classes - it contains 3 rows for the 3 classes    
  #comparing each test review text with patterns from each of the classes
  for k in (0..num_classes - 1)
    #comparing edges with patterns from a particular class
    class_prob[k] = compare_review_with_patterns(edges, single_patterns[k], wordnet)/6.to_f #normalizing the result 
    #we divide the match by 6 to ensure the value is in the range of [0-1]     
  end #end of for loop for the classes          
  
  return class_prob
end #end of the prediction method
#------------------------------------------#------------------------------------------#------------------------------------------
def get_max(a,b)
 if(a>b)
  return a
 end
 return b
end
 
def compare_review_with_patterns(single_edges, single_patterns, wordnet)
  final_class_sum = 0.0
  final_edge_num = 0
  single_edge_matches = Array.new(single_edges.length){Array.new}
  #resetting the average_match values for all the edges, before matching with the single_patterns for a new class
  for i in 0..single_edges.length - 1
    if(!single_edges[i].nil?)
      single_edges[i].average_match = 0
    end  
  end
  
  #comparing each single edge with all the patterns
  puts(single_edges.length)
  puts single_patterns.length
  for i in (0..single_edges.length - 1)  #iterating through the single edges
    max_match = 0
    if(!single_edges[i].nil?)
      for j in (0..single_patterns.length - 1) 
        if(!single_patterns[j].nil?)
          single_edge_matches[i][j] = compare_edges(single_edges[i], single_patterns[j], wordnet)
          max_match = get_max(single_edge_matches[i][j],max_match) 
        end 
      end #end of for loop for the patterns
      single_edges[i].average_match = max_match  
      
      #calculating class average
      if(single_edges[i].average_match != 0.0)
        final_class_sum = final_class_sum + single_edges[i].average_match
        final_edge_num+=1
      end
    end #end of the if condition
  end #end of for loop
  
  if(final_edge_num == 0)
    final_edge_num = 1  
  end
  
  
  return final_class_sum/final_edge_num #maxMatch
end #end of determineClass method
#------------------------------------------#------------------------------------------#------------------------------------------
def compare_edges(e1, e2, wordnet)
  speller = FFI::Aspell::Speller.new('en_US')
  
  avg_match_without_syntax = 0
  #compare edges so that only non-nouns or non-subjects are compared
  in_in_vertex_compare = wordnet.compare_strings(e1.in_vertex, e2.in_vertex, speller)
  in_out_vertex_compare = wordnet.compare_strings(e1.in_vertex, e2.out_vertex, speller)
  out_out_vertex_compare = wordnet.compare_strings(e1.out_vertex, e2.out_vertex, speller)
  out_in_vertex_compare = wordnet.compare_strings(e1.out_vertex, e2.in_vertex, speller)
  avg_match_without_syntax = (in_in_vertex_compare + out_out_vertex_compare)/2.to_f
  
  avg_match_with_syntax = 0
  #matching in-out and out-in vertices
  avg_match_with_syntax = (in_out_vertex_compare + out_in_vertex_compare)/2.to_f
  
  if(avg_match_without_syntax > avg_match_with_syntax)
    return avg_match_without_syntax
  else
    return avg_match_with_syntax
  end
end #end of the compare_edges method
end
