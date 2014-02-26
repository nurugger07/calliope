defmodule CalliopeSafeTest do
  use ExUnit.Case

  import Calliope.Safe

  test :eval_safe_script do
    assert "&lt;script&rt;a bad script&lt;/script&rt;" ==
      eval_safe_script "val", [val: "<script>a bad script</script>"]

    assert "<script>a good script</script>" ==
      eval_safe_script "Safe.script(val)", [val: "<script>a good script</script>"]
    assert "<script>a good script</script>" ==
      eval_safe_script "Safe.script val", [val: "<script>a good script</script>"]
  end

  test :clean do
    assert "&lt;script&rt;a bad script&lt;/script&rt;" ==
      clean "<script>a bad script</script>"
    assert [ arg: "&lt;script&rt;a bad script &amp; more&lt;/script&rt;" ] ==
      clean [ arg: "<script>a bad script & more</script>" ]
  end

end
