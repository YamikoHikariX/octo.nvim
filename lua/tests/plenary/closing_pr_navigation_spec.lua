---@diagnostic disable
local eq = assert.are.same

describe("go_to_closing_pr:", function()
  local navigation
  local utils
  local opened
  local info_messages
  local selected_items
  local select_choice
  local prs

  local function issue_buffer()
    return {
      repo = "owner/repo",
      isIssue = function()
        return true
      end,
      closingPrs = prs,
    }
  end

  before_each(function()
    opened = nil
    info_messages = {}
    selected_items = nil
    select_choice = nil
    prs = {
      { number = 11, title = "first" },
      { number = 12, title = "second" },
    }

    navigation = require "octo.navigation"
    utils = require "octo.utils"

    utils.info = function(msg)
      table.insert(info_messages, msg)
    end
    utils.get_pull_request = function(number, repo)
      opened = { number = number, repo = repo }
    end
    utils.get_current_buffer = issue_buffer
    vim.ui.select = function(items, _, on_choice)
      selected_items = items
      on_choice(select_choice)
    end
  end)

  after_each(function()
    package.loaded["octo.navigation"] = nil
    package.loaded["octo.utils"] = nil
  end)

  it("opens the only pull request", function()
    prs = { { number = 11, title = "first" } }
    navigation.go_to_closing_pr()
    eq({ number = 11, repo = "owner/repo" }, opened)
    eq(nil, selected_items)
  end)

  it("offers a choice when several pull requests close the issue", function()
    select_choice = prs[2]
    navigation.go_to_closing_pr()
    eq(prs, selected_items)
    eq({ number = 12, repo = "owner/repo" }, opened)
  end)

  it("opens nothing when the choice is dismissed", function()
    navigation.go_to_closing_pr()
    eq(nil, opened)
  end)

  it("notifies when no pull request closes the issue", function()
    prs = {}
    navigation.go_to_closing_pr()
    eq(nil, opened)
    eq(1, #info_messages)
  end)

  it("does nothing outside issue buffers", function()
    utils.get_current_buffer = function()
      return nil
    end
    navigation.go_to_closing_pr()
    eq(nil, opened)
    eq(0, #info_messages)
  end)
end)
