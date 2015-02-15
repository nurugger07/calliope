defmodule CalliopeIntegerationTest do
  use ExUnit.Case

  use Calliope.Render

  @haml """
- if false do
  %p true
- else 
  %p false
"""
  test :else_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>false</p>" 
  end

  @haml """
- if true do
  %p true
- else 
  %p false
"""
  test :if_result_with_else do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end
 
  @haml """
- if true do
  %p true
"""
  test :if_true_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end
 
  @haml """
- if false do
  %p true
"""
  test :if_false_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == ""
  end

  @haml """
- unless false do
  %p true
"""
  test :uneless_false_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end

  @haml """
- unless true do
  %p false
- else 
  %p true
"""
  test :unless_result_with_else do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end
 
  @haml ~S(
- answer = "42"
%p
  The answer is
  = " #{answer}"
)
  test :local_variable do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>The answer is 42</p>"
  end

  @haml ~S(
- for x <- [1,2] do
  %p= x
)
  test :for_evaluation do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>1</p><p>2</p>"
  end

  @haml ~S(
- case 1 + 1 do
  - 1 -> 
    %p Got one
  - 2 ->
    %p Got two
  - other -> 
    %p= "Got other #{other}"
)
  test :case_evaluation do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>Got two</p>"
  end
end
