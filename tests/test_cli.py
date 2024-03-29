"""Tests the cli functions.

There is an overlap between these tests and the one in test_lib, but these are
more a placeholder for tests than an example of ideal test strategy.
"""

import subprocess

import pytest
import typer.testing

import python_example

# Pylint will complain that the fixture gets redefined as an input argument, so
# ignore it for this file.
# pylint: disable=redefined-outer-name


@pytest.fixture()
def runner() -> typer.testing.CliRunner:
    """Fixture defining a test runner for the cli.

    Read more about typer testing:
    https://typer.tiangolo.com/tutorial/testing/

    Read more about pytest fixtures:
    https://docs.pytest.org/en/6.2.x/fixture.html
    """
    return typer.testing.CliRunner()


def test_invoke_cli(runner: typer.testing.CliRunner) -> None:
    """Test that the cli can be invoked without crashing."""
    result = runner.invoke(python_example.app, ["--help"])
    assert result.exit_code == 0


def test_invoke_as_module() -> None:
    """Test that the cli can be invoked as a python module without crashing."""
    result = subprocess.run(
        ["python3", "-m", "python_example", "--help"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf-8",
        check=True,
    )
    assert result.returncode == 0


def test_addition(runner: typer.testing.CliRunner) -> None:
    """Test the addition command by adding numbers."""
    result = runner.invoke(
        python_example.app, ["add", "--number", "1", "--number", "2", "--number", "3"]
    )
    assert "Result: 6" in result.stdout


def test_hello(runner: typer.testing.CliRunner) -> None:
    """Test saying hello to the world."""
    result = runner.invoke(python_example.app, ["hello", "World!"])
    assert "Hello World!" in result.stdout
