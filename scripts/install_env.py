#!/usr/bin/env python3
"""
Environment-specific installer with integrated shared models management
Usage: install_env.py <environment> [skip_models|status]
Examples: 
  install_env.py comm
  install_env.py comm skip_models
  install_env.py comm status
  
Features:
- Automatic environment-specific installation
- Integrated shared models management (replaces setup_shared_models.sh)
- Automatic symlink creation for model sharing
- Smart model backup and migration
- Status checking and debugging capabilities
"""

import os
import sys
import subprocess
import shutil
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)


class ComfyUIEnvironmentInstaller:
    """Manages the installation of ComfyUI environments"""
    
    def __init__(self, environment: str, skip_models: bool = False):
        self.environment = environment
        self.skip_models = skip_models
        self.env_dir = Path(f"/workspace/ComfyUI-{environment}")
        self.build_dir = Path(f"/build/{environment}")
        self.shared_models_dir = Path("/workspace/shared-models")
            
    def check_existing_installation(self) -> bool:
        """Check if environment is already installed"""
        if self.env_dir.exists():
            logger.info(f"Environment {self.environment} already exists at {self.env_dir}")
            logger.info("Skipping installation")
            return True
        return False
        
    def check_build_scripts(self) -> None:
        """Verify build scripts exist"""
        if not self.build_dir.exists():
            logger.error(f"Build scripts not found for environment: {self.environment}")
            logger.error(f"Expected directory: {self.build_dir}")
            sys.exit(1)
            
        install_script = self.build_dir / "install.sh"
        if not install_script.exists():
            logger.error(f"install.sh not found in {self.build_dir}")
            sys.exit(1)
            
    def prepare_install_script(self) -> Path:
        """Copy and modify the install script for environment-specific installation"""
        logger.info("Copying build scripts...")
        
        # Create temporary directory
        temp_dir = Path(f"/tmp/build-{self.environment}")
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        shutil.copytree(self.build_dir, temp_dir)
        
        # Modify the install script
        install_script = temp_dir / "install.sh"
        logger.info("Modifying install script for environment-specific installation...")
        
        with open(install_script, 'r') as f:
            content = f.read()
            
        # Replace /ComfyUI with environment-specific path (but not in Git URLs)
        import re
        # Split into lines and process each line separately to avoid regex issues
        lines = content.split('\n')
        modified_lines = []
        
        for line in lines:
            # Skip git clone lines entirely
            if 'git clone' in line and '/ComfyUI' in line:
                # Replace only the target path in git clone
                line = re.sub(r'(git clone .+?\.git)\s+/ComfyUI', r'\1 ' + str(self.env_dir), line)
            else:
                # Replace /ComfyUI in other contexts
                line = re.sub(r'/ComfyUI(?=\s|$)', str(self.env_dir), line)
            modified_lines.append(line)
        
        content = '\n'.join(modified_lines)
        
        with open(install_script, 'w') as f:
            f.write(content)
            
        return temp_dir
        
    def run_installation(self, temp_dir: Path) -> None:
        """Execute the installation script"""
        # Set environment variables
        env = os.environ.copy()
        env.update({
            'COMFYUI_VERSION': os.getenv('COMFYUI_COMMIT', 'master'),
            'TORCH_VERSION': os.getenv('TORCH_VERSION', '2.6.0+cu124'),
            'XFORMERS_VERSION': os.getenv('XFORMERS_VERSION', '0.0.29.post3'),
            'INDEX_URL': os.getenv('INDEX_URL', 'https://download.pytorch.org/whl/cu124')
        })
        
        logger.info(f"Running environment-specific installation...")
        logger.info(f"COMFYUI_VERSION={env['COMFYUI_VERSION']}")
        logger.info(f"TORCH_VERSION={env['TORCH_VERSION']}")
        logger.info(f"XFORMERS_VERSION={env['XFORMERS_VERSION']}")
        logger.info(f"INDEX_URL={env['INDEX_URL']}")
        
        install_script = temp_dir / "install.sh"
        
        try:
            # Run installation with real-time output
            logger.info("Starting installation script execution...")
            result = subprocess.run(
                ['bash', str(install_script)],
                env=env,
                check=True,
                text=True
            )
            logger.info("Installation script completed successfully")
        except subprocess.CalledProcessError as e:
            logger.error(f"Installation failed with exit code {e.returncode}")
            logger.error("Check the output above for detailed error information")
            sys.exit(1)
            
    def create_shared_models_structure(self) -> None:
        """Create shared models directory structure"""
        logger.info("Creating shared models directory structure...")
        
        # Create main shared models directory
        self.shared_models_dir.mkdir(parents=True, exist_ok=True)
        
        # Create standard ComfyUI model subdirectories
        model_types = [
            'checkpoints', 'loras', 'controlnet', 'vae', 
            'clip_vision', 'ipadapter', 'instantid', 'insightface'
        ]
        
        for model_type in model_types:
            model_dir = self.shared_models_dir / model_type
            model_dir.mkdir(exist_ok=True)
            logger.info(f"Created model directory: {model_dir}")
        
        logger.info(f"Shared models directory structure created at {self.shared_models_dir}")

    def move_models_to_shared(self, env_models_dir: Path) -> None:
        """Move models from environment to shared directory"""
        if not env_models_dir.exists():
            logger.info(f"Source models directory not found: {env_models_dir}")
            return
        
        logger.info(f"Moving models from {env_models_dir} to shared directory...")
        
        model_types = [
            'checkpoints', 'loras', 'controlnet', 'vae',
            'clip_vision', 'ipadapter', 'instantid', 'insightface'
        ]
        
        for model_type in model_types:
            source_dir = env_models_dir / model_type
            target_dir = self.shared_models_dir / model_type
            
            if source_dir.exists():
                logger.info(f"Moving {model_type} models...")
                
                # Create target directory if it doesn't exist
                target_dir.mkdir(exist_ok=True)
                
                # Move files (not overwrite existing)
                try:
                    for file_path in source_dir.iterdir():
                        if file_path.is_file():
                            target_file = target_dir / file_path.name
                            if not target_file.exists():
                                shutil.copy2(file_path, target_file)
                                logger.info(f"Moved: {file_path.name}")
                            else:
                                logger.info(f"Skipped existing: {file_path.name}")
                except Exception as e:
                    logger.warning(f"Error moving {model_type} models: {e}")
        
        logger.info("Models moved to shared directory")

    def create_models_symlink(self) -> None:
        """Create symbolic link for models directory"""
        models_dir = self.env_dir / "models"
        
        logger.info(f"Creating models symlink for {self.env_dir}...")
        
        # Remove existing models directory if it exists
        if models_dir.exists():
            if models_dir.is_dir() and not models_dir.is_symlink():
                logger.info("Backing up existing models to shared directory...")
                self.move_models_to_shared(models_dir)
                shutil.rmtree(models_dir)
            elif models_dir.is_symlink():
                logger.info("Removing existing symlink...")
                models_dir.unlink()
        
        # Create symbolic link
        try:
            models_dir.symlink_to(self.shared_models_dir)
            logger.info(f"Symbolic link created: {models_dir} -> {self.shared_models_dir}")
        except Exception as e:
            logger.error(f"Failed to create symbolic link: {e}")
            raise

    def create_input_symlink(self) -> None:
        """Create symbolic link for input directory"""
        logger.info(f"Creating input symlink for {self.env_dir}...")
        
        # Base ComfyUI directory
        base_input_dir = Path("/workspace/ComfyUI/input")
        
        # Environment-specific directory
        env_input_dir = self.env_dir / "input"
        
        # Create base directory if it doesn't exist
        base_input_dir.mkdir(parents=True, exist_ok=True)
        
        # Create symlink for input directory
        if env_input_dir.exists():
            if env_input_dir.is_symlink():
                logger.info("Removing existing input symlink...")
                env_input_dir.unlink()
            elif env_input_dir.is_dir():
                # Move existing files to base directory
                logger.info("Moving existing input files to base directory...")
                for file_path in env_input_dir.iterdir():
                    target = base_input_dir / file_path.name
                    if not target.exists():
                        shutil.move(str(file_path), str(target))
                shutil.rmtree(env_input_dir)
        
        # Create symbolic link
        try:
            env_input_dir.symlink_to(base_input_dir)
            logger.info(f"Symbolic link created: {env_input_dir} -> {base_input_dir}")
        except Exception as e:
            logger.error(f"Failed to create input symbolic link: {e}")
            raise

    def setup_shared_models(self) -> None:
        """Setup shared models for the environment"""
        logger.info(f"Setting up shared models for {self.environment}...")
        
        # Create shared models directory if it doesn't exist
        if not self.shared_models_dir.exists():
            self.create_shared_models_structure()
        
        # Check if environment directory exists
        if not self.env_dir.exists():
            logger.error(f"Environment directory not found: {self.env_dir}")
            raise FileNotFoundError(f"Environment directory not found: {self.env_dir}")
        
        # Create models symlink
        self.create_models_symlink()
        
        logger.info(f"Shared models setup completed for {self.environment}")

    def check_shared_models_status(self) -> None:
        """Check shared models status (for debugging)"""
        logger.info("=== Shared Models Status Report ===")
        
        # Check shared models directory
        if self.shared_models_dir.exists():
            logger.info(f"Shared models directory: EXISTS ({self.shared_models_dir})")
            
            # Count models in each subdirectory
            model_types = [
                'checkpoints', 'loras', 'controlnet', 'vae',
                'clip_vision', 'ipadapter', 'instantid', 'insightface'
            ]
            
            for model_type in model_types:
                model_dir = self.shared_models_dir / model_type
                if model_dir.exists():
                    model_count = len([f for f in model_dir.iterdir() if f.is_file()])
                    logger.info(f"  {model_type}: {model_count} models")
        else:
            logger.info("Shared models directory: NOT FOUND")
        
        # Check environment symlink
        models_dir = self.env_dir / "models"
        if models_dir.is_symlink():
            target = models_dir.readlink()
            logger.info(f"Environment symlink: {models_dir} -> {target} ✓")
        elif models_dir.is_dir():
            logger.info(f"Environment models: DIRECTORY (not symlinked)")
        else:
            logger.info(f"Environment models: NOT FOUND")
            
    def download_models(self, temp_dir: Path) -> None:
        """Download models if needed"""
        if self.skip_models:
            logger.info("Skipping model downloads as requested")
            return
            
        model_script = temp_dir / "comm-models-download.sh"
        if not model_script.exists():
            logger.info(f"No model download script found for {self.environment}")
            return
            
        logger.info(f"Downloading models for {self.environment}...")
        
        # Modify model download script to use correct paths
        with open(model_script, 'r') as f:
            content = f.read()
            
        # Replace /workspace/ComfyUI with environment-specific path
        content = content.replace(
            '/workspace/ComfyUI',
            str(self.env_dir)
        )
        
        # Also replace models directory with shared models
        content = content.replace(
            f'{self.env_dir}/models', 
            str(self.shared_models_dir)
        )
        
        with open(model_script, 'w') as f:
            f.write(content)
            
        try:
            # Run model download with real-time output
            logger.info("Starting model download script execution...")
            result = subprocess.run(
                ['bash', str(model_script)],
                check=True,
                text=True
            )
            logger.info("Model download script completed successfully")
        except subprocess.CalledProcessError as e:
            logger.error(f"Model download failed: {e}")
            # Don't exit on model download failure
            
    def verify_installation(self) -> None:
        """Verify the installation completed successfully"""
        main_py = self.env_dir / "main.py"
        venv_dir = self.env_dir / "venv"
        
        if main_py.exists() and venv_dir.exists():
            logger.info("Installation verification PASSED")
        else:
            logger.error("Installation verification FAILED")
            if not main_py.exists():
                logger.error(f"main.py not found in {self.env_dir}")
            if not venv_dir.exists():
                logger.error(f"venv directory not found in {self.env_dir}")
            sys.exit(1)
            
    def cleanup(self, temp_dir: Path) -> None:
        """Clean up temporary files"""
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
            
    def run_fix_dependencies(self) -> None:
        """Run environment-specific dependency fix script"""
        fix_script = Path(f"/config/environments/{self.environment}/fix_dependencies.sh")
        
        if not fix_script.exists():
            logger.warning(f"No fix_dependencies.sh found for {self.environment}")
            return
            
        # Check if virtual environment exists
        venv_pip = self.env_dir / "venv" / "bin" / "pip"
        if not venv_pip.exists():
            logger.error(f"Virtual environment pip not found: {venv_pip}")
            return
            
        logger.info("=" * 60)
        logger.info(f"🔧 Running dependency fixes for environment: {self.environment}")
        logger.info(f"📁 Working directory: {self.env_dir}")
        logger.info(f"🐍 Virtual environment: {self.env_dir / 'venv'}")
        logger.info(f"📜 Fix script: {fix_script}")
        logger.info("=" * 60)
        
        try:
            # Run the fix script with proper environment variables and working directory
            env = os.environ.copy()
            env['VIRTUAL_ENV'] = str(self.env_dir / "venv")
            env['PATH'] = f"{self.env_dir / 'venv' / 'bin'}:{env.get('PATH', '')}"
            
            cmd = f"bash {fix_script}"
            logger.info(f"🚀 Executing command: {cmd}")
            
            result = subprocess.run(
                cmd, 
                shell=True, 
                check=True, 
                text=True,
                cwd=str(self.env_dir),
                env=env
            )
            
            logger.info("=" * 60)
            logger.info("✅ Dependency fixes completed successfully")
            logger.info("=" * 60)
            
        except subprocess.CalledProcessError as e:
            logger.error("=" * 60)
            logger.error(f"❌ Dependency fix failed with exit code: {e.returncode}")
            logger.error(f"🚀 Command executed: {cmd}")
            logger.error(f"📁 Working directory: {self.env_dir}")
            logger.error("=" * 60)
            raise
            
    def install(self) -> None:
        """Main installation process"""
        
        # Check if already installed
        if self.check_existing_installation():
            # Environment exists, but ensure shared models and custom nodes are complete
            logger.info("Environment exists, ensuring shared models and custom nodes are complete...")
            self.setup_shared_models()
            
            # Create input symlink
            self.create_input_symlink()
            
            # Download custom nodes and models using universal downloader
            try:
                import subprocess
                logger.info(f"Running universal downloader for {self.environment}...")
                result = subprocess.run([
                    'python3', '/universal_downloader.py', self.environment
                ], check=True, text=True)
                logger.info("Universal downloader completed successfully")
            except subprocess.CalledProcessError as e:
                logger.error(f"Universal downloader failed: {e}")
                # Continue anyway, some downloads might have succeeded
            
            # Run dependency fixes after universal downloader
            self.run_fix_dependencies()
            
            return
            
        # Check build scripts exist
        self.check_build_scripts()
        
        temp_dir = None
        try:
            # Prepare installation
            temp_dir = self.prepare_install_script()
            
            # Run installation
            self.run_installation(temp_dir)
            
            # Setup shared models
            self.setup_shared_models()
            
            # Create input symlink
            self.create_input_symlink()
            
            # Download models
            self.download_models(temp_dir)
            
            # Run dependency fixes after installation
            self.run_fix_dependencies()
            
            # Log completion
            logger.info(f"ComfyUI environment {self.environment} installation completed")
            logger.info(f"Environment directory: {self.env_dir}")
            logger.info(f"Models directory: {self.env_dir}/models -> {self.shared_models_dir}")
            logger.info(f"Input directory: {self.env_dir}/input -> /workspace/ComfyUI/input")
            
            # Verify installation
            self.verify_installation()
            
        finally:
            # Cleanup
            if temp_dir:
                self.cleanup(temp_dir)


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        logger.error("Environment name required (comm)")
        print(f"Usage: {sys.argv[0]} <environment> [skip_models|status]")
        print("Examples:")
        print(f"  {sys.argv[0]} comm")
        print(f"  {sys.argv[0]} comm skip_models")
        print(f"  {sys.argv[0]} comm status")
        sys.exit(1)
        
    environment = sys.argv[1]
    
    # Check for special commands
    if len(sys.argv) > 2:
        if sys.argv[2] == 'status':
            installer = ComfyUIEnvironmentInstaller(environment, skip_models=True)
            installer.check_shared_models_status()
            return
        elif sys.argv[2] == 'skip_models':
            skip_models = True
        else:
            skip_models = False
    else:
        skip_models = False
    
    installer = ComfyUIEnvironmentInstaller(environment, skip_models)
    installer.install()


if __name__ == "__main__":
    main()